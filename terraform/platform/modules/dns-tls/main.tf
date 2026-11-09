# Both lookups fail the plan early with a clear error if a prerequisite is missing.
data "aws_route53_zone" "this" {
  name         = var.domain_name
  private_zone = false
}

data "aws_acm_certificate" "this" {
  domain      = var.certificate_domain
  statuses    = ["ISSUED"]
  most_recent = true
}
