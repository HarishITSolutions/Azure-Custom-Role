#provide configuration details for the azure terraform provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      #version = "~>3.23.0"
    }
  }
}
provider "azurerm" {
  skip_provider_registration = "true"
  subscription_id            = var.subscriptionID
  tenant_id                  = var.tenantID
  client_id                  = var.clientID
  client_secret              = var.clientSecret
  features {}
}

provider "azuread" {
  tenant_id     = var.tenantID
  client_id     = var.clientID
  client_secret = var.clientSecret
}


