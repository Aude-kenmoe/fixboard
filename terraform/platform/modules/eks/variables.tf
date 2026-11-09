variable "cluster_name" {
  type = string
}

variable "kubernetes_version" {
  description = "Kubernetes version of the control plane."
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  description = "Subnets for the nodes and the control plane network interfaces."
  type        = list(string)
}

variable "public_access_cidrs" {
  description = "CIDR ranges allowed to reach the public Kubernetes API endpoint."
  type        = list(string)
}

variable "node_instance_types" {
  type = list(string)
}

variable "node_min_size" {
  type = number
}

variable "node_max_size" {
  type = number
}

variable "node_desired_size" {
  type = number
}
