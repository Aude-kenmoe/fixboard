output "role_arn" {
  description = "Role the GitHub Actions workflow assumes."
  value       = aws_iam_role.pipeline.arn
}
