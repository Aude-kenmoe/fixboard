variable "domain_name" {
  description = "Domain with a public hosted zone in Route 53, for example example.com."
  type        = string
}

variable "certificate_domain" {
  description = "Primary domain name of the issued ACM certificate, for example *.example.com."
  type        = string
}
