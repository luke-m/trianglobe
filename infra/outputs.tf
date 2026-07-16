# Outputs = values printed after `apply` (and queryable anytime via
# `terraform output`): the facts the outside world needs from this stack.

output "ecr_repository_url" {
  description = "Push/pull address of the image repository"
  value       = aws_ecr_repository.app.repository_url
}

output "app_url" {
  description = "Public address of the deployed app"
  value       = "http://${aws_eip.app.public_ip}"
}

output "ci_role_arn" {
  description = "Set as the AWS_ROLE_ARN repository variable on GitHub"
  value       = aws_iam_role.ci.arn
}

output "instance_id" {
  description = "For a shell via: aws ssm start-session --target <id>"
  value       = aws_instance.app.id
}
