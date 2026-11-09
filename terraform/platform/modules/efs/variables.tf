variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnets, one mount target is created in each."
  type        = list(string)
}

variable "subnet_count" {
  description = "Number of subnets in subnet_ids. Passed separately so it is known at plan time."
  type        = number
}

variable "allowed_security_group_id" {
  description = "Security group of the cluster nodes."
  type        = string
}
