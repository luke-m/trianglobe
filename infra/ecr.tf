# The image repository CI pushes to and the EC2 instance pulls from.
# Resource address = type + local name: aws_ecr_repository.app. The local
# name ("app") exists only inside Terraform; AWS sees `name = "trianglobe"`.
resource "aws_ecr_repository" "app" {
  name         = "trianglobe"
  force_delete = true # let `terraform destroy` work even with images inside
}

# ECR bills per stored GB, and every main-branch push adds an image.
# This policy is ECR-side garbage collection: keep the newest 10, expire the rest.
resource "aws_ecr_lifecycle_policy" "app" {
  repository = aws_ecr_repository.app.name # reference = dependency: repo is created first

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}
