variable "hostname" {
  description = "Public hostname for the ArgoCD UI, for example argocd.example.com."
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate that covers the hostname."
  type        = string
}

variable "chart_version" {
  description = "Optional Argo CD chart version. Unset means latest."
  type        = string
  default     = null
}
