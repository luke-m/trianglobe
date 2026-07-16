# The AWS half of the keyless-CI handshake. GitHub half: the `id-token: write`
# permission and configure-aws-credentials step in .github/workflows/ci.yml.

# Registers GitHub as a trusted identity provider in this AWS account:
# "tokens issued by this URL, verified against its published keys, may be
# presented here." The thumbprint identifies the issuer's TLS chain.
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# TRUST policy: who may become the CI role. This is the blast door.
data "aws_iam_policy_document" "ci_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    # The token must have been requested for AWS, not some other audience.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # The token's subject must be EXACTLY our repo's main branch.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repository}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "ci" {
  name               = "trianglobe-ci"
  assume_role_policy = data.aws_iam_policy_document.ci_assume_role.json
}

# PERMISSION policy: what the CI role may do — push images, nothing else.
data "aws_iam_policy_document" "ci_ecr_push" {
  statement {
    # Registry-wide by AWS design: this action cannot be scoped to one repo.
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    resources = [aws_ecr_repository.app.arn] # our one repository, nothing else
  }
}

resource "aws_iam_role_policy" "ci_ecr_push" {
  name   = "ecr-push"
  role   = aws_iam_role.ci.id
  policy = data.aws_iam_policy_document.ci_ecr_push.json
}
