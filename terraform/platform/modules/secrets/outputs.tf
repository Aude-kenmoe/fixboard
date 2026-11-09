output "db_credentials_name" {
  value = aws_secretsmanager_secret.db_credentials.name
}

output "backend_secrets_name" {
  value = aws_secretsmanager_secret.backend_secrets.name
}

output "secret_arns" {
  description = "ARNs the External Secrets Operator is allowed to read."
  value = [
    aws_secretsmanager_secret.db_credentials.arn,
    aws_secretsmanager_secret.backend_secrets.arn,
  ]
}
