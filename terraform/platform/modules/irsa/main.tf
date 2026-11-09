# A thin wrapper so every add-on gets its IAM role the same way.
module "role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.52"

  role_name = var.role_name

  attach_load_balancer_controller_policy = var.attach_load_balancer_controller_policy
  attach_efs_csi_policy                  = var.attach_efs_csi_policy
  attach_external_secrets_policy         = var.attach_external_secrets_policy
  attach_external_dns_policy             = var.attach_external_dns_policy

  external_secrets_secrets_manager_arns = var.external_secrets_secrets_manager_arns
  external_dns_hosted_zone_arns         = var.external_dns_hosted_zone_arns

  role_policy_arns = var.role_policy_arns

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = var.namespace_service_accounts
    }
  }
}
