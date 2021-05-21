# First Instance

## Introduction

This lab will help you learn the fundamentals of Terraform and using it to provision infrastructure on Azure.

As you progress through the lab, you'll use Terraform to provision, update and destroy a more complexe infrastructure, with two Azure Container Instances behind an Traffic Manager DNS in Azure.

## Prerequisite - First Option - Local Run

To do this lab from your local environment, you will need to install Az cli and Terraform.
* **Azure CLI** - You must have the Azure CLI installed on your local computer. Version 2.10.1 or later is recommended. Run `az --version` to find the version. If you need to install or upgrade, see [Install the Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli).

* **Terraform** - You must have [Terraform](hthttps://www.terraform.io/downloads.html).

After installing the tools, open a new shell (Powershell or bash) and move into a clean directory as you will create new files.

## Prerequisite - Second Option - CloudShell

If you want to do the lab without installing this tools, you can use [CloudShell](https://shell.azure.com). CloudShell is a Powershell or bash shell directly embeddeded in your browser, with tools like Terraform available and a context already authenticated with your Azure account.

After opening the shell, you can click on the two braces in the upper left corner to open the file explorer.
Using the shell, move into a new directory for the lab as you will create new files:
```bash
cd clouddrive
mkdir complexscenario
cd complexscenario
```

If you can't find file or directories you create in the explorer, use the refresh button in the left side to reload the tree.

## Instruction

1. We will first set up a basic configuration for Terraform. We will setup a local backend to manage our tfstate file and Azure Resource Manager as a provider.
    
    1. Create a `main.tf` file, that will be our template file:
        ```bash
        touch main.tf
        ```
    1. Using the file explorer, open `main.tf` and add your local backend:
        ```terraform
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
        ```
    
1. Run the command `terraform init` for Terraform to load the configuration.

1. We will first add a local data source to store our tags. This way, we can resuse the same tags for all our resources. Add to main.tf file:
    ```bash
    locals {
        tags = {
            "project"     = var.myproject
            "environment" = var.env
        }
    }
    ```

1. As you can see, we are not setting explicit values, instead, we are using variables. To define variable, you will create a new file, `variables.tf` and add the variables definitions with default values:
    ```bash
    touch variables.tf
    ```

    Then, open the file and add your variables. we will also add the location and informations about the docker image we want to use later:
    ```terraform
    variable "env" {
        default = "dev"
    }

    variable "myproject" {
        default = "<myproject>"
    }

    variable "region" {
        default = "eastus"
    }

    variable "imagename" {
        default = "nginx"
    }

    variable "imageversion" {
        default = "latest"
    }
    ```
    
    Don't forget to replace the default value for the variable myproject, or you can override it when running `terraform apply` by using the `-var` flag.
    Save your file and go back to `main.tf`.


1. Now add a azurerm_resource_group resource inside your main.tf file:
    ```bash
    resource "azurerm_resource_group" "rg" {
        name     = "${var.myproject}-rg"
        location = var.region
        tags     = local.tags
    }
    ```

1. Now, we will add a first Azure Container instance, that may act as our blue environment for a Blue-Green deployment:
    ```terraform
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
    ```

    The Azure Container Instance will automatically load our nginx image and expose port 80. We also defined the performances we want for our container.

1. We will add a second container that will act as our Green environment in a Blue-Green deployment, or as a backup/redundant environment:
    ```terraform
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
    ```

1. Now, we add our DNS endpoint: Traffic Manager
    ```terraform
    resource "azurerm_traffic_manager_profile" "main" {
        name                   = "${var.myproject}-tm"
        resource_group_name    = azurerm_resource_group.rg.name
        traffic_routing_method = "Weighted"

        dns_config {
            relative_name = "${var.myproject}-tm"
            ttl           = 30
        }

        monitor_config {
            protocol = "http"
            port     = 80
            path     = "/"
        }
    }
    ```

    This will create a new Traffic Manager instance within the same resource group. We will be using a weighted algorithm to distribute the traffic, meaning that we control which percentage of traffic is sent to each environment.
    We also define a monitoring endpoint for ou backend and the Time To Live of our DNS.

1. We can now add our two backend endpoints to target our two Azure Container Instances:
    ```terraform
    resource "azurerm_traffic_manager_endpoint" "blue" {
        name                = "${var.myproject}-tm-blue"
        resource_group_name = azurerm_resource_group.rg.name
        profile_name        = azurerm_traffic_manager_profile.main.name
        type                = "externalEndpoints"
        target              = azurerm_container_group.containergroup.fqdn
        weight              = 999
        }

        resource "azurerm_traffic_manager_endpoint" "green" {
        name                = "${var.myproject}-tm-green"
        resource_group_name = azurerm_resource_group.rg.name
        profile_name        = azurerm_traffic_manager_profile.main.name
        type                = "externalEndpoints"
        target              = azurerm_container_group.containergroup-green.fqdn
        weight              = 1
    }
    ```

1. Your final terraform file should look like:
    ```terraform
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

    resource "azurerm_traffic_manager_profile" "main" {
        name                   = "${var.myproject}-tm"
        resource_group_name    = azurerm_resource_group.rg.name
        traffic_routing_method = "Weighted"

        dns_config {
            relative_name = "${var.myproject}-tm"
            ttl           = 30
        }

        monitor_config {
            protocol = "http"
            port     = 80
            path     = "/"
        }
    }

    resource "azurerm_traffic_manager_endpoint" "blue" {
        name                = "${var.myproject}-tm-blue"
        resource_group_name = azurerm_resource_group.rg.name
        profile_name        = azurerm_traffic_manager_profile.main.name
        type                = "externalEndpoints"
        target              = azurerm_container_group.containergroup.fqdn
        weight              = 999
        }

        resource "azurerm_traffic_manager_endpoint" "green" {
        name                = "${var.myproject}-tm-green"
        resource_group_name = azurerm_resource_group.rg.name
        profile_name        = azurerm_traffic_manager_profile.main.name
        type                = "externalEndpoints"
        target              = azurerm_container_group.containergroup-green.fqdn
        weight              = 1
    }
    ```

1. Finally, as we want to get the traffic manager endpoint as an output in the console, we will create an `output.tf` file and add the variable:
    ```terraform
    output "traffic_manager_fqdn" {
        value = azurerm_traffic_manager_profile.main.fqdn
    }
    ```

1. Ready to deploy? Let's go!
    ```bash
    terraform apply
    ```

    You can also change the variable when applying the configuration. For exemple, to change the project name:
    ```bash
    terraform apply -var myproject="project"
    ```

    After agreeing to the changes, they are apply. When it's done, you will see, in the console, your traffic maanger fqdn as an output:
    ```bash
    ...
    Apply complete! Resources: 2 added, 1 changed, 2 destroyed.

    Outputs:

    traffic_manager_fqdn = "<project>-tm.trafficmanager.net"
    ``` 
    
    Open this URL in your web browser, and you should see nginx default page!

    If you want, you can play with [Traffic Manager](https://docs.microsoft.com/en-us/azure/traffic-manager/traffic-manager-configure-weighted-routing-method). For exemple, you can remove juste one ACI from your template, and check that it is still running, or deleting it manually to simulate an error with your application.

1. After your done, you can remove all the resources by using terraform:
    ```bash
    terraform destroy
    ```

    After you agree, the resource group and all the resources within will be deleted.
