locals {
  argocd_hostname  = coalesce(var.argocd_hostname, "argocd.${var.domain_name}")
  grafana_hostname = coalesce(var.grafana_hostname, "grafana.${var.domain_name}")
}

# ---------------------------------------------------------------------------
# Phase 1 baseline: always on
# ---------------------------------------------------------------------------
module "network" {
  source = "./modules/network"

  name         = var.cluster_name
  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr
  az_count     = var.az_count
}

module "eks" {
  source = "./modules/eks"

  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  vpc_id              = module.network.vpc_id
  private_subnet_ids  = module.network.private_subnet_ids
  public_access_cidrs = var.api_public_access_cidrs
  node_instance_types = var.node_instance_types
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size
}

module "ecr" {
  source = "./modules/ecr"

  name_prefix = var.project_name
}

module "rds" {
  source = "./modules/rds"

  name                      = var.project_name
  vpc_id                    = module.network.vpc_id
  db_subnet_group_name      = module.network.database_subnet_group_name
  allowed_security_group_id = module.eks.node_security_group_id
  instance_class            = var.rds_instance_class
  multi_az                  = var.rds_multi_az
}

module "efs" {
  source = "./modules/efs"

  name                      = var.project_name
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.private_subnet_ids
  subnet_count              = var.az_count
  allowed_security_group_id = module.eks.node_security_group_id
}

module "secrets" {
  source = "./modules/secrets"

  name_prefix = var.project_name
  db_host     = module.rds.address
  db_port     = module.rds.port
  db_name     = module.rds.db_name
  db_username = module.rds.username
  db_password = module.rds.password
}

module "dns_tls" {
  source = "./modules/dns-tls"

  domain_name        = var.domain_name
  certificate_domain = var.certificate_domain
}

module "addons" {
  source = "./modules/addons"

  cluster_name       = var.cluster_name
  region             = var.region
  vpc_id             = module.network.vpc_id
  oidc_provider_arn  = module.eks.oidc_provider_arn
  efs_file_system_id = module.efs.file_system_id
  secret_arns        = module.secrets.secret_arns
  domain_name        = module.dns_tls.domain_name
  hosted_zone_arn    = module.dns_tls.zone_arn
  chart_versions     = var.chart_versions

  # Wait for the node group, not only the control plane.
  depends_on = [module.eks]
}

# ---------------------------------------------------------------------------
# Phase 2: GitOps
# ---------------------------------------------------------------------------
module "github_oidc" {
  count  = var.enable_gitops ? 1 : 0
  source = "./modules/github-oidc"

  name                 = var.project_name
  github_repository    = var.github_repository
  github_branch        = var.github_branch
  create_oidc_provider = var.create_github_oidc_provider
  ecr_repository_arns  = values(module.ecr.repository_arns)
}

module "gitops" {
  count  = var.enable_gitops ? 1 : 0
  source = "./modules/gitops"

  hostname        = local.argocd_hostname
  certificate_arn = module.dns_tls.certificate_arn

  depends_on = [module.addons]
}

# ---------------------------------------------------------------------------
# Phase 3: Observability
# ---------------------------------------------------------------------------
module "observability" {
  count  = var.enable_observability ? 1 : 0
  source = "./modules/observability"

  cluster_name      = var.cluster_name
  region            = var.region
  oidc_provider_arn = module.eks.oidc_provider_arn
  grafana_hostname  = local.grafana_hostname
  certificate_arn   = module.dns_tls.certificate_arn
  chart_versions    = var.chart_versions

  depends_on = [module.addons]
}
