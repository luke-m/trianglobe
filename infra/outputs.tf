# Outputs = values printed after `apply` (and queryable anytime via
# `terraform output`): the facts the outside world needs from this stack.

output "ecr_repository_url" {
  description = "Push/pull address of the image repository"
  value       = aws_ecr_repository.app.repository_url
}
