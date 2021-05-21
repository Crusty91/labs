# Define Azure provider
        provider "azurerm" {
            features {}
        }

        # Define backend configuration with Azure storage for the tfstate file
        terraform {
            backend "local" {
                path  = "./tstate"
            }
            required_providers {
                azurerm = {
                source = "hashicorp/azurerm"
                version = "=2.43.0"
                }
            }
        }

        locals {
            tags = {
                "project"     = var.myproject
                "environment" = var.env
            }
        }

        resource "azurerm_resource_group" "rg" {
            name     = "${var.myproject}-rg"
            location = var.region
            tags     = local.tags
        }

        resource "azurerm_container_group" "containergroup" {
            name                  = "${var.myproject}-aci"
            resource_group_name   = azurerm_resource_group.rg.name
            location              = azurerm_resource_group.rg.location
            ip_address_type       = "public"
            dns_name_label        = "${var.myproject}-aci"
            os_type               = "Linux"

            container {
                name   = "${var.myproject}-aci"
                image  = "${var.imagename}:${var.imageversion}"
                cpu    = "0.5"
                memory = "1.5"

                ports {
                port     = 80
                protocol = "TCP"
                }
            }
        }

        resource "azurerm_container_group" "containergroup-green" {
            name                  = "${var.myproject}-aci-green"
            resource_group_name   = azurerm_resource_group.rg.name
            location              = azurerm_resource_group.rg.location
            ip_address_type       = "public"
            dns_name_label        = "${var.myproject}-aci-green"
            os_type               = "Linux"

            container {
                name   = "${var.myproject}-aci"
                image  = "${var.imagename}:${var.imageversion}"
                cpu    = "0.5"
                memory = "1.5"

                ports {
                port     = 80
                protocol = "TCP"
                }
            }
        }

        module "trafficmanager" {
  source = "./modules/trafficmanager"
    rgname = azurerm_resource_group.rg.name
    prefix = var.myproject
    target_blue = azurerm_container_group.containergroup.fqdn
    target_green = azurerm_container_group.containergroup-green.fqdn
}
