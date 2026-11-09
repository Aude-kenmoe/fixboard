variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "efs_file_system_id" {
  type = string
}

variable "secret_arns" {
  description = "Secrets Manager secrets the External Secrets Operator may read."
  type        = list(string)
}

variable "domain_name" {
  description = "Domain ExternalDNS is allowed to manage records for."
  type        = string
}

variable "hosted_zone_arn" {
  description = "ARN of the Route 53 hosted zone for the domain."
  type        = string
}

variable "chart_versions" {
  description = "Optional Helm chart versions by key (alb, external_secrets, external_dns). Unset means latest."
  type        = map(string)
  default     = {}
}
