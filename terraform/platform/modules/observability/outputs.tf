output "grafana_url" {
  value = "https://${var.grafana_hostname}"
}

output "grafana_admin_password" {
  value     = random_password.grafana.result
  sensitive = true
}

output "log_group_name" {
  value = aws_cloudwatch_log_group.containers.name
}
