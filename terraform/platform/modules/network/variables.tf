variable "name" {
  description = "Name prefix for the VPC and its resources."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name, used for the subnet discovery tags."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use (at least 2, RDS needs two)."
  type        = number
  default     = 2
}
