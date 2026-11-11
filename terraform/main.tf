terraform {
  required_version = ">= 1.3.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "kubernetes" {
  config_path = pathexpand(var.kubeconfig_path)
}

resource "kubernetes_namespace" "kijani_staging" {
  metadata {
    name = var.staging_namespace
    labels = {
      environment = "staging"
      managed_by  = "terraform"
      project     = "kijanikiosk"
    }
  }
}

resource "kubernetes_resource_quota" "staging_quota" {
  metadata {
    name      = "kijani-staging-quota"
    namespace = kubernetes_namespace.kijani_staging.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "1"
      "requests.memory" = "1Gi"
      "limits.cpu"      = "2"
      "limits.memory"   = "2Gi"
      "pods"            = "10"
    }
  }
}
