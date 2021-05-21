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
mkdir moduleandbackend
cd moduleandbackend
```

If you can't find file or directories you create in the explorer, use the refresh button in the left side to reload the tree.

## Instruction

### Create your first module

1. First, we will re-create the three files we had at the end of the previous lab:
    1. `variables.tf`:
        ```terraform
        variable "env" {
            default = "dev"
        }

        variable "myproject" {
            default = "barbotshop"
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
    1. `output.tf`:
        ```terraform
        output "traffic_manager_fqdn" {
            value = azurerm_traffic_manager_profile.main.fqdn
        }
        ```
    1. `main.tf`:
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

    We will try to improve this configuration for collaboration and reusability.

1. We will extract the Traffic Manager and the two wheighted policies in a nested module.
    1. Create a directory called trafficmanager inside a new directory called modules
    ```bash
    mkdir -p modules/trafficmanager
    cd modules/trafficmanager
    ```

    1. Create a file with the required variables. For the purpose of the lab, we will decide that the parameters are
        - routing_policy: which routing policy we want to use, weighted by default
        - rgname: name of the resource group you want to deploy to
        - prefix: prefix used to name your new resources
        - target_blue: the endpoint to be target with most of the traffic
        - target_green: the secondary endpoint
        Create `variables.tf`, add the variables:
            ```terraform
            variable "routing_policy" {
                default = "Weighted"
            }
            
            variable "rgname" {
                default = "myrg"
            }

            variable "prefix" {
                default = "webapp"
            }

            variable "target_blue" {}

            variable "target_green" {}
            ```
    1. now, we will create the `main.tf` file. We will simply copy the lines in the original template to create the traffic manager, and replace some field by variables references:
        ```terraform
        resource "azurerm_traffic_manager_profile" "main" {
            name                   = "${var.prefix}-tm"
            resource_group_name    = var.rgname
            traffic_routing_method = var.routing_policy

            dns_config {
                relative_name = "${var.prefix}-tm"
                ttl           = 30
            }

            monitor_config {
                protocol = "http"
                port     = 80
                path     = "/"
            }
        }

        resource "azurerm_traffic_manager_endpoint" "blue" {
            name                = "${var.prefix}-tm-blue"
            resource_group_name = var.rgname
            profile_name        = azurerm_traffic_manager_profile.main.name
            type                = "externalEndpoints"
            target              = var.target_blue
            weight              = 999
            }

            resource "azurerm_traffic_manager_endpoint" "green" {
            name                = "${var.prefix}-tm-green"
            resource_group_name = var.rgname
            profile_name        = azurerm_traffic_manager_profile.main.name
            type                = "externalEndpoints"
            target              = var.target_green
            weight              = 1
        }
        ```

    1. We will also add the output file to get the traffic manager endpoint as an output of the module. Create `output.tf` and add:
    ```terraform
    output "traffic_manager_fqdn" {
        value = azurerm_traffic_manager_profile.main.fqdn
    }
    ``` 

1. We need to call this new module from `main.tf`. First, we will clean up the file, then replace with a call to the module. Open `moduleandbackend/main.tf` and remove sections about azurerm_traffic_manager_profile and the two azurerm_traffic_manager_endpoint. Then, add the call to the nested module:
    ```terraform
    module "trafficmanager" {
        source = "./modules/trafficmanager"
        rgname = azurerm_resource_group.rg.name
        prefix = var.myproject
        target_blue = azurerm_container_group.containergroup.fqdn
        target_green = azurerm_container_group.containergroup-green.fqdn
    }
    ```

1. You should also update the `output.tf` file in the `moduleandbackend` to reference the module output instead of the previous output:
    ```terraform
    output "traffic_manager_fqdn" {
        value = module.trafficmanager.traffic_manager_fqdn
    }
    ```

1. You can now validate that your files are well formed by running `terraform appy` command. You should achieve the same result as in the previous lab: if you open the url in the output, you should see the nginx default page.

    If you want to see the solution, you can check the expected files [here](./3-ModuleAndBackend-Solution)

1. Clean up the resources using `terraform destroy`
    You should also manually delete terraform leftovers:
    ```bash
    rm -rf .terraform .terraform.lock.hcl tstate tstate.backup
    ```

### Use a remote backend

As you saw, the state of your infrastructure is really important for Terraform to know which resources are managed and what is their status. This state is store in a state file that is local... for now. AS we want to collabore and share our state between multiple people in the team, we will need a way host it remotly.

In the section, we will use an Azure Storage account as a backend for our state file. This way, wherever you are running your terraform commands, as you are referencing the same state file, you will be synchronized in our changes.

#### Create an Azure Storage Account

As the storage account will be used by Terraform itself, you can not use your template to create the resource group nor the storage account. To create an azure storage account, we can simply use the az cli command:
```azcli
 az group create -g mycommonrg -l eastus
 az storage account create --name <account-name> -g mycommonrg -l eastus
 az storage container create -n tstate --account-name <account-name> -g mycommonrg
```

Before continuing, you will need a couple of information:
 - the resource group name: mycommonrg
 - the storage account name: <account-name>
 - the subscription id: 
    ```azcli
    az account show --query id
    ```

#### Change your backend and deploy your infrastructure

1. Now that our backend is created, we will need to update our `main.tf` file in our project directory. Open `main.tf` and locate the definition of the backend:
    ```terraform
    ...
    terraform {
        backend "local" {
            path  = "./tstate"
        }
    ...
    ```

    We will replace this local backend by azurerm. You will need to use the information you noted previously to fill some values. Leave container_name and key as it, it is used to create the state file on the storage account:
    ```terraform
    terraform {
        backend "azurerm" {
            resource_group_name  = "mycommonrg"
            storage_account_name = <account-name>
            container_name       = "tstate"
            key                  = "terraform.barbotshop.tfstate"
            subscription_id      = <subscription-id>
        }
    ```

1. With this new backend defined, you can run your `terraform init` command and `terraform apply` to deploy your infrastructure.

1. If you want, when your infrastructure is deployed, you can take a look at your state file by going into the azure portal and opening your storage account.
    1. go into azure portal
    1. find your resource group "mycommonrg"
    1. In your ressource group, find your storage account <account-name>
    1. In your storage account, in the left blade, under **Data Storage**, select **Containers**
    1. Click on the container named **tstate**
    1. You should see a file, click on it and click the **Download** button to download the file.

1. You can try updating the configuration, on your computer if you are using cloudshell, or on cloudshell if you are using your computer. As the state is remote, it will still be able to process the update.

1. Clean up the resources using `terraform destroy`
1. Clean up your resource group:
    ```bash
    az group delete -g mycommonrg
    ```


