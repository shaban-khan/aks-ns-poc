terraform {
  # required_version = "~> 1.14.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.8.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.58"
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
}

# azurerm feature toggles
provider "azurerm" {
  subscription_id = var.subscription_id
  features {
  }
}

