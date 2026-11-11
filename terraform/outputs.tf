output "staging_namespace_name" {
  description = "Provisioned Kubernetes namespace for staging"
  value       = kubernetes_namespace.kijani_staging.metadata[0].name
}
