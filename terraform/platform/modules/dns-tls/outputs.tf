output "domain_name" {
  value = var.domain_name
}

output "zone_id" {
  value = data.aws_route53_zone.this.zone_id
}

output "zone_arn" {
  value = data.aws_route53_zone.this.arn
}

output "certificate_arn" {
  value = data.aws_acm_certificate.this.arn
}
