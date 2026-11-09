output "storage_class_name" {
  value = kubernetes_storage_class_v1.efs.metadata[0].name
}

output "cluster_secret_store_name" {
  value = "aws-secrets-manager"
}
