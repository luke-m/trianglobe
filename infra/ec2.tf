# Every AWS account ships with a default VPC (network) per region; using it
# keeps M0 minimal. `data` blocks READ existing things; `resource` blocks own them.
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Amazon Linux 2023 AMI (the disk template the VM boots from),
# resolved through AWS's public SSM parameter instead of a hardcoded ID.
data "aws_ssm_parameter" "al2023_ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Rules live in standalone resources (the provider-recommended pattern);
# the group itself is just the container. Never mix in inline rules.
# Port 22 is absent by design: shell access goes through SSM, not SSH.
resource "aws_security_group" "app" {
  name        = "trianglobe-app"
  description = "Public HTTP in; no SSH (shell access via SSM). Everything out."
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "http_in" {
  security_group_id = aws_security_group.app.id
  description       = "Inbound HTTP (Port 80) traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "https_in" {
  security_group_id = aws_security_group.app.id
  description       = "Inbound HTTPs (Port 443) traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

# Outbound: unrestricted (the instance must reach ECR, SSM, dnf mirrors).
resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.app.id
  description       = "All outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # all protocols; port range must be omitted with -1
}

# What the SERVER may do (contrast: trianglobe-ci is what CI may do):
# pull images + talk to SSM. Trust policy: only the EC2 service itself
# may wear this role — this is how credentials appear on the box keylessly.
resource "aws_iam_role" "instance" {
  name = "trianglobe-instance"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "instance_ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "instance_ecr_pull" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    # Pull-only: the read half of CI's push permissions.
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = [aws_ecr_repository.app.arn]
  }
}

resource "aws_iam_role_policy" "instance_ecr_pull" {
  name   = "ecr-pull"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.instance_ecr_pull.json
}

# The bridge that hands a role to a VM.
resource "aws_iam_instance_profile" "app" {
  name = "trianglobe-app"
  role = aws_iam_role.instance.name
}

resource "aws_instance" "app" {
  ami                    = data.aws_ssm_parameter.al2023_ami.insecure_value
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.app.id]
  iam_instance_profile   = aws_iam_instance_profile.app.name

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    region    = var.region
    ecr_url   = aws_ecr_repository.app.repository_url
    image_tag = var.image_tag
  })

  # Changed image_tag -> changed user_data -> fresh instance running the new
  # tag. Brutal but honest M0 redeploys; also free chaos-engineering practice.
  user_data_replace_on_change = true

  tags = {
    Name = "trianglobe-app"
  }
}

# Stable public IPv4 that survives instance replacement (the address recruiters
# bookmark must not change on every redeploy).
resource "aws_eip" "app" {
  tags = {
    Name = "trianglobe-app"
  }
}

resource "aws_eip_association" "app" {
  instance_id   = aws_instance.app.id
  allocation_id = aws_eip.app.id
}
