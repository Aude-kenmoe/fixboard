variable "role_name" {
  description = "Name of the IAM role to create."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster OIDC provider."
  type        = string
}

variable "namespace_service_accounts" {
  description = "Service accounts allowed to assume the role, as namespace:name."
  type        = list(string)
}

variable "attach_load_balancer_controller_policy" {
  type    = bool
  default = false
}

variable "attach_efs_csi_policy" {
  type    = bool
  default = false
}

variable "attach_external_secrets_policy" {
  type    = bool
  default = false
}

variable "external_secrets_secrets_manager_arns" {
  type    = list(string)
  default = ["arn:aws:secretsmanager:*:*:secret:*"]
}

variable "attach_external_dns_policy" {
  type    = bool
  default = false
}

variable "external_dns_hosted_zone_arns" {
  type    = list(string)
  default = ["arn:aws:route53:::hostedzone/*"]
}

variable "role_policy_arns" {
  description = "Extra managed policies to attach, as a map of name to ARN."
  type        = map(string)
  default     = {}
}
