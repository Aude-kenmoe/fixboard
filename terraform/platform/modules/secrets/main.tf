# Signing key for the application tokens. Generated once, shared by every pod.
resource "random_password" "jwt" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.name_prefix}/db-credentials"
  description = "FixBoard database connection details"

  # No recovery window, so a destroy followed by an apply can reuse the name.
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    dbname   = var.db_name
    host     = var.db_host
    port     = tostring(var.db_port)
  })
}

resource "aws_secretsmanager_secret" "backend_secrets" {
  name                    = "${var.name_prefix}/backend-secrets"
  description             = "FixBoard backend application secrets"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "backend_secrets" {
  secret_id = aws_secretsmanager_secret.backend_secrets.id

  secret_string = jsonencode({
    JWT_SECRET = random_password.jwt.result
  })
}
