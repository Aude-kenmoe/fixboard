locals {
  role_annotation = "eks.amazonaws.com/role-arn"
}

# ---------------------------------------------------------------------------
# AWS Load Balancer Controller: turns Ingress objects into ALBs
# ---------------------------------------------------------------------------
module "alb_controller_role" {
  source = "../irsa"

  role_name                              = "${var.cluster_name}-alb-controller"
  oidc_provider_arn                      = var.oidc_provider_arn
  namespace_service_accounts             = ["kube-system:aws-load-balancer-controller"]
  attach_load_balancer_controller_policy = true
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = try(var.chart_versions["alb"], null)
  namespace  = "kube-system"

  values = [yamlencode({
    clusterName = var.cluster_name
    region      = var.region
    vpcId       = var.vpc_id
    serviceAccount = {
      create = true
      name   = "aws-load-balancer-controller"
      annotations = {
        (local.role_annotation) = module.alb_controller_role.role_arn
      }
    }
  })]
}

# ---------------------------------------------------------------------------
# metrics-server: needed by the Horizontal Pod Autoscaler and kubectl top
# ---------------------------------------------------------------------------
resource "aws_eks_addon" "metrics_server" {
  cluster_name = var.cluster_name
  addon_name   = "metrics-server"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

# ---------------------------------------------------------------------------
# EFS CSI driver and the StorageClass students use for shared uploads
# ---------------------------------------------------------------------------
module "efs_csi_role" {
  source = "../irsa"

  role_name         = "${var.cluster_name}-efs-csi"
  oidc_provider_arn = var.oidc_provider_arn
  namespace_service_accounts = [
    "kube-system:efs-csi-controller-sa",
    "kube-system:efs-csi-node-sa",
  ]
  attach_efs_csi_policy = true
}

resource "aws_eks_addon" "efs_csi" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-efs-csi-driver"
  service_account_role_arn = module.efs_csi_role.role_arn

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "kubernetes_storage_class_v1" "efs" {
  metadata {
    name = "efs-sc"
  }

  storage_provisioner = "efs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "Immediate"

  # Each claim gets its own EFS access point under /dynamic.
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId     = var.efs_file_system_id
    directoryPerms   = "700"
    basePath         = "/dynamic"
    gidRangeStart    = "1000"
    gidRangeEnd      = "2000"
  }

  depends_on = [aws_eks_addon.efs_csi]
}

# ---------------------------------------------------------------------------
# External Secrets Operator: syncs Secrets Manager entries into Kubernetes
# ---------------------------------------------------------------------------
module "external_secrets_role" {
  source = "../irsa"

  role_name                             = "${var.cluster_name}-external-secrets"
  oidc_provider_arn                     = var.oidc_provider_arn
  namespace_service_accounts            = ["external-secrets:external-secrets"]
  attach_external_secrets_policy        = true
  external_secrets_secrets_manager_arns = var.secret_arns
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = try(var.chart_versions["external_secrets"], null)
  namespace        = "external-secrets"
  create_namespace = true

  values = [yamlencode({
    installCRDs = true
    serviceAccount = {
      create = true
      name   = "external-secrets"
      annotations = {
        (local.role_annotation) = module.external_secrets_role.role_arn
      }
    }
  })]

  depends_on = [helm_release.alb_controller]
}

# A cluster-wide store that points at Secrets Manager. Applications only
# create an ExternalSecret that references it.
resource "helm_release" "secret_store" {
  name      = "secret-store"
  chart     = "${path.module}/charts/secret-store"
  namespace = "external-secrets"

  values = [yamlencode({
    name   = "aws-secrets-manager"
    region = var.region
  })]

  depends_on = [helm_release.external_secrets]
}

# ---------------------------------------------------------------------------
# ExternalDNS: creates Route 53 records for the hosts used in Ingress objects
# ---------------------------------------------------------------------------
module "external_dns_role" {
  source = "../irsa"

  role_name                     = "${var.cluster_name}-external-dns"
  oidc_provider_arn             = var.oidc_provider_arn
  namespace_service_accounts    = ["external-dns:external-dns"]
  attach_external_dns_policy    = true
  external_dns_hosted_zone_arns = [var.hosted_zone_arn]
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart            = "external-dns"
  version          = try(var.chart_versions["external_dns"], null)
  namespace        = "external-dns"
  create_namespace = true

  values = [yamlencode({
    provider      = { name = "aws" }
    sources       = ["ingress"]
    domainFilters = [var.domain_name]
    policy        = "sync"
    registry      = "txt"
    txtOwnerId    = var.cluster_name
    env = [
      { name = "AWS_DEFAULT_REGION", value = var.region }
    ]
    serviceAccount = {
      create = true
      name   = "external-dns"
      annotations = {
        (local.role_annotation) = module.external_dns_role.role_arn
      }
    }
  })]

  depends_on = [helm_release.alb_controller]
}
