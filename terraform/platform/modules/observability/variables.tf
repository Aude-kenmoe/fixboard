variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "grafana_hostname" {
  description = "Public hostname for Grafana, for example grafana.example.com."
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate that covers the Grafana hostname."
  type        = string
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "chart_versions" {
  description = "Optional chart versions by key (prometheus_stack, fluent_bit). Unset means latest."
  type        = map(string)
  default     = {}
}
