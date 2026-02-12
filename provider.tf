terraform {
  # required_version = "~> 1.14.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.8.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.58"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.8.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-skdemo-aks-02"
    storage_account_name = "skdemosa999"
    container_name       = "aksns-tfstate"
    key                  = "aks/managed-namespaces.tfstate"
  }
}

# AzureRM provider
provider "azurerm" {
  subscription_id = var.subscription_id
  features {}
}

# 🔑 Kubernetes provider (FIXED — no localhost issue)
provider "kubernetes" {
  host = data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].host

  cluster_ca_certificate = base64decode(
    data.azurerm_kubernetes_cluster.aks_cluster.kube_config[0].cluster_ca_certificate
  )

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "kubelogin"
    args = [
      "get-token",
      "--login",
      "azurecli",
      "--server-id",
      "6dae42f8-4368-4678-94ff-3960e28e3630"
    ]
  }
}