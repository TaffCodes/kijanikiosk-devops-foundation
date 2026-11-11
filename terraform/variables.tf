variable "kubeconfig_path" {
  description = "Path to the Kubernetes configuration file"
  type        = string
  default     = "~/.kube/config"
}

variable "staging_namespace" {
  description = "Isolated Kubernetes namespace for staging workloads"
  type        = string
  default     = "kijani-staging"
}
