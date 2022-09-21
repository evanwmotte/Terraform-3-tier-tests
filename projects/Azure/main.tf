terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

module "resourcegroup" {
  source   = "../../modules/azure/resourcegroup"
  name     = var.name
  location = var.location
}

module "networking" {
  source         = "../../modules/azure/network"
  location       = module.resourcegroup.location_id
  resource_group = module.resourcegroup.resource_group_name
  vnetcidr       = var.vnetcidr
  websubnetcidr  = var.websubnetcidr
  appsubnetcidr  = var.appsubnetcidr
  dbsubnetcidr   = var.dbsubnetcidr
}

module "securitygroup" {
  source         = "../../modules/azure/securitygroup"
  location       = module.resourcegroup.location_id
  resource_group = module.resourcegroup.resource_group_name
  web_subnet_id  = module.networking.websubnet_id
  app_subnet_id  = module.networking.appsubnet_id
  db_subnet_id   = module.networking.dbsubnet_id
}

module "compute" {
  source          = "../../modules/azure/compute"
  location        = module.resourcegroup.location_id
  resource_group  = module.resourcegroup.resource_group_name
  web_subnet_id   = module.networking.websubnet_id
  app_subnet_id   = module.networking.appsubnet_id
  web_host_name   = var.web_host_name
  web_username    = var.web_username
  web_os_password = var.web_os_password
  app_host_name   = var.app_host_name
  app_username    = var.app_username
  app_os_password = var.app_os_password
}

module "database" {
  source                    = "../../modules/azure/database"
  location                  = module.resourcegroup.location_id
  resource_group            = module.resourcegroup.resource_group_name
  primary_database          = var.primary_database
  primary_database_version  = var.primary_database_version
  primary_database_admin    = var.primary_database_admin
  primary_database_password = var.primary_database_password
}
