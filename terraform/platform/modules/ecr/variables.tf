variable "name_prefix" {
  description = "Prefix for the repository names, for example fixboard."
  type        = string
}

variable "repository_names" {
  description = "Repositories to create under the prefix."
  type        = list(string)
  default     = ["backend", "frontend"]
}

variable "keep_last_images" {
  description = "How many images to keep per repository."
  type        = number
  default     = 20
}
