variable "name" {
  type = string
}

variable "github_repository" {
  description = "Repository allowed to assume the role, as owner/name."
  type        = string
}

variable "github_branch" {
  description = "Branch allowed to assume the role."
  type        = string
  default     = "main"
}

variable "create_oidc_provider" {
  description = "Set to false if the account already has the GitHub OIDC provider (only one is allowed per account)."
  type        = bool
  default     = true
}

variable "ecr_repository_arns" {
  description = "Repositories the pipeline may push to."
  type        = list(string)
}
