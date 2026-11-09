output "cluster_name" {
  value = module.eks.cluster_name
}

output "kubeconfig_command" {
  description = "Run this to point kubectl at the cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "ecr_repository_urls" {
  description = "Where the backend and frontend images are pushed."
  value       = module.ecr.repository_urls
}

output "rds_endpoint" {
  description = "Database host, for the ExternalName Service."
  value       = module.rds.address
}

output "efs_file_system_id" {
  value = module.efs.file_system_id
}

output "storage_class_name" {
  description = "StorageClass for the shared uploads claim."
  value       = module.addons.storage_class_name
}

output "cluster_secret_store_name" {
  description = "Name students reference from an ExternalSecret."
  value       = module.addons.cluster_secret_store_name
}

output "db_credentials_secret" {
  value = module.secrets.db_credentials_name
}

output "backend_secrets_secret" {
  value = module.secrets.backend_secrets_name
}

output "certificate_arn" {
  description = "ACM certificate for the Ingress annotation."
  value       = module.dns_tls.certificate_arn
}

output "hosted_zone_id" {
  value = module.dns_tls.zone_id
}

output "github_actions_role_arn" {
  description = "Phase 2: role the workflow assumes."
  value       = try(module.github_oidc[0].role_arn, null)
}

output "argocd_url" {
  description = "Phase 2."
  value       = try(module.gitops[0].url, null)
}

output "argocd_admin_password_command" {
  description = "Phase 2: prints the initial admin password."
  value       = var.enable_gitops ? "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d" : null
}

output "grafana_url" {
  description = "Phase 3."
  value       = try(module.observability[0].grafana_url, null)
}

output "grafana_admin_password" {
  description = "Phase 3. Show with: terraform output -raw grafana_admin_password"
  value       = try(module.observability[0].grafana_admin_password, null)
  sensitive   = true
}

output "log_group_name" {
  description = "Phase 3: CloudWatch log group for container logs."
  value       = try(module.observability[0].log_group_name, null)
}
