# ---------------------------------------------------------------------------
# General
# ---------------------------------------------------------------------------
variable "region" {
  description = "AWS region for everything. The ACM certificate must be issued here."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used for ECR repositories, secrets and tags."
  type        = string
  default     = "fixboard"
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
  default     = "ridgeline-fixboard"
}

# ---------------------------------------------------------------------------
# DNS and TLS prerequisites (must already exist in the account)
# ---------------------------------------------------------------------------
variable "domain_name" {
  description = "Domain with a public hosted zone in Route 53, for example example.com."
  type        = string
}

variable "certificate_domain" {
  description = "Primary domain name of the issued ACM certificate, for example *.example.com."
  type        = string
}

# ---------------------------------------------------------------------------
# Network and cluster
# ---------------------------------------------------------------------------
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of availability zones (2 or 3)."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3
    error_message = "az_count must be 2 or 3."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version. Check the EKS version calendar before changing it."
  type        = string
  default     = "1.35"
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_min_size" {
  type    = number
  default = 2
}

variable "node_max_size" {
  type    = number
  default = 4
}

variable "node_desired_size" {
  type    = number
  default = 2
}

variable "api_public_access_cidrs" {
  description = "CIDR ranges allowed to reach the Kubernetes API. Narrow this to your own IP for anything beyond a class."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------
variable "rds_instance_class" {
  type    = string
  default = "db.t3.micro"
}

variable "rds_multi_az" {
  type    = bool
  default = false
}

# ---------------------------------------------------------------------------
# Phase switches
# ---------------------------------------------------------------------------
variable "enable_gitops" {
  description = "Phase 2: GitHub Actions role for ECR and ArgoCD."
  type        = bool
  default     = false
}

variable "enable_observability" {
  description = "Phase 3: Prometheus, Grafana, Alertmanager and Fluent Bit."
  type        = bool
  default     = false
}

# ---------------------------------------------------------------------------
# Phase 2 settings
# ---------------------------------------------------------------------------
variable "github_repository" {
  description = "Repository the pipeline runs from, as owner/name."
  type        = string
  default     = ""
}

variable "github_branch" {
  type    = string
  default = "main"
}

variable "create_github_oidc_provider" {
  description = "Set to false if the AWS account already has the GitHub OIDC provider."
  type        = bool
  default     = true
}

variable "argocd_hostname" {
  description = "ArgoCD hostname. Defaults to argocd.<domain_name>."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Phase 3 settings
# ---------------------------------------------------------------------------
variable "grafana_hostname" {
  description = "Grafana hostname. Defaults to grafana.<domain_name>."
  type        = string
  default     = null
}

# ---------------------------------------------------------------------------
# Helm chart versions (leave empty for latest, pin once a working set is known)
# ---------------------------------------------------------------------------
variable "chart_versions" {
  description = "Chart versions by key: alb, external_secrets, external_dns, prometheus_stack, fluent_bit."
  type        = map(string)
  default     = {}
}
