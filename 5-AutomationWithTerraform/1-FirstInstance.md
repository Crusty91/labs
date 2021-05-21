# First Instance

## Introduction

This lab will help you learn the fundamentals of TErraform and using it to provision infrastructure on Azure.

As you progress through the lab, you'll use Terraform to provision, update and destroy a simple VM in Azure.

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
mkdir firstinstance
cd firstinstance
```

If you can't find file or directories you create in the explorer, use the refresh button in the left side to reload the tree.

## Instruction

1. First, you can verify that Terraform is correctly installed by running:
    ```bash
    terraform --version
    ```
    You may receive a warning that a new version is available for Terraform if you are using cloudshell. You don't need to update the version to run the lab as it was tested in cloudshell.

1. We will first set up a basic configuration for Terraform. We will setup a local backend to manage our tfstate file.
    
    1. Create a `main.tf` file, that will be our template file:
        ```bash
        touch main.tf
        ```
    1. Using the file explorer, open `main.tf` and add your local backend:
        ```terraform
        terraform {
            backend "local" {
                path  = "./tstate"
            }
        }
        ```
    
1. Now that your first configuration is created, you are ready to run your first command. The first command to run for a new configuration -- or after checking out an
existing configuration from version control -- is `terraform init`. It will
initializes local settings and data that will be used byother commands.

    Initialize your new Terraform configuration by running the `terraform init`
command in the same directory as your main.tf file.

    ```bash
    terraform init
    ```

    The result should be similar to:
    ```bash
    sylvain@Azure:~/clouddrive/firstinstance$ terraform init

    Initializing the backend...

    Successfully configured the backend "local"! Terraform will automatically
    use this backend unless the backend configuration changes.

    Initializing provider plugins...

    Terraform has been successfully initialized!

    You may now begin working with Terraform. Try running "terraform plan" to see
    any changes that are required for your infrastructure. All Terraform commands
    should now work.

    If you ever set or change modules or backend configuration for Terraform,
    rerun this command to reinitialize your working directory. If you forget, other
    commands will detect it and remind you to do so if necessary.
    ```
1. Now, we will add a provider to our configuration. The provider is basically what backend service will be used to create resources. As we are using Azure, we will add the Azure backend. 

    Open again your main.tf file. At the top of the file, add azure provider by adding this lines:
    ```bash
    # Configure the Microsoft Azure Provider
    provider "azurerm" {
        features {}
    }
    ```

    As you can see, we are adding the provider Azure Resource Manager. You can see a list of available providers [here](https://registry.terraform.io/browse/providers).

    We will also add the attribute required_provider to Terraform configuration to explicitly define the version we want to use.

    Your main.tf file should look like:
    ```bash
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

    Run the command `terraform init` again for Terraform to load the provider:
    ```bash
    sylvain@Azure:~/clouddrive/firstinstance$ terraform init

    Initializing the backend...

    Successfully configured the backend "local"! Terraform will automatically
    use this backend unless the backend configuration changes.

    Initializing provider plugins...
    - Finding hashicorp/azurerm versions matching "2.43.0"...
    - Installing hashicorp/azurerm v2.43.0...
    - Installed hashicorp/azurerm v2.43.0 (signed by HashiCorp)

    Terraform has created a lock file .terraform.lock.hcl to record the provider
    selections it made above. Include this file in your version control repository
    so that Terraform can guarantee to make the same selections by default when
    you run "terraform init" in the future.

    Terraform has been successfully initialized!

    You may now begin working with Terraform. Try running "terraform plan" to see
    any changes that are required for your infrastructure. All Terraform commands
    should now work.

    If you ever set or change modules or backend configuration for Terraform,
    rerun this command to reinitialize your working directory. If you forget, other
    commands will detect it and remind you to do so if necessary.
    ```

1. You Terraform environment is now setup to create resources. To work with Azure resources, we will need to create a resource group. Add a azurerm_resource_group resource inside your main.tf file:
    ```bash
    resource "azurerm_resource_group" "rg" {
        name     = "myresourcegroup"
        location = "East US"
        tags = {
            "project" = "webapp"
        }
    }
    ```

    If you want, you can apply this first template by running the following command in the shell:
    ```bash
    terraform apply
    ```
    You will be asked for validation. Review the changes (creation of a resource group), and if you agree, the resource group will be created and a first tfstate file will be create with your resources information in the current directory. You can also open the azure portal to view your resource group.

1. We will now create a Virtual Machine into this resource group. a virtual machine itself require other resources to be deployed first.
    1. Add a Virtual Network:
    ```terraform
    resource "azurerm_virtual_network" "main" {
        name                = "myvnet"
        address_space       = ["10.0.0.0/16"]
        location            = azurerm_resource_group.rg.location
        resource_group_name = azurerm_resource_group.rg.name
    }
    ```
    As you can see, to define the location and resource group name for the virtual network, we are simply using a reference to the previously defined resource group. By doing so, we are also creating a dependency between the network and the resource group.
    We also define the adress space and the name.

    1. Add a Subnet:
    ```terraform
    resource "azurerm_subnet" "internal" {
        name                 = "internal"
        resource_group_name  = azurerm_resource_group.rg.name
        virtual_network_name = azurerm_virtual_network.main.name
        address_prefixes     = ["10.0.2.0/24"]
    }
    ```
    Again, we create a dependency between the subnet, the resource group and the virtual network. We also define the adress space.

    1. Add a network interface:
    ```terraform
    resource "azurerm_network_interface" "main" {
        name                = "mynic"
        location            = azurerm_resource_group.rg.location
        resource_group_name = azurerm_resource_group.rg.name

        ip_configuration {
            name                          = "testconfiguration1"
            subnet_id                     = azurerm_subnet.internal.id
            private_ip_address_allocation = "Dynamic"
        }
    }
    ```

    1. Create the VM:
    ```terraform
    resource "azurerm_virtual_machine" "main" {
        name                  = "myvm"
        location              = azurerm_resource_group.rg.location
        resource_group_name   = azurerm_resource_group.rg.name
        network_interface_ids = [azurerm_network_interface.main.id]
        vm_size               = "Standard_DS1_v2"

        storage_image_reference {
            publisher = "Canonical"
            offer     = "UbuntuServer"
            sku       = "16.04-LTS"
            version   = "latest"
        }

        storage_os_disk {
            name              = "myosdisk1"
            caching           = "ReadWrite"
            create_option     = "FromImage"
            managed_disk_type = "Standard_LRS"
        }
        os_profile {
            computer_name  = "hostname"
            admin_username = "myselftest"
            admin_password = "Password1234!"
        }
        os_profile_linux_config {
            disable_password_authentication = false
        }
    }
    ```

    So with this resource, we are creating a VM resouce. We set the size to Standard_DS1_V2, the operating system to Ubuntu 16.04, we define our VM disk, our admin credentials.


    Your final terraform file should look like:
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

    resource "azurerm_resource_group" "rg" {
        name     = "myresourcegroup"
        location = "East US"
        tags = {
            "project" = "webapp"
        }
    }

    resource "azurerm_virtual_network" "main" {
        name                = "myvnet"
        address_space       = ["10.0.0.0/16"]
        location            = azurerm_resource_group.rg.location
        resource_group_name = azurerm_resource_group.rg.name
    }

    resource "azurerm_subnet" "internal" {
        name                 = "internal"
        resource_group_name  = azurerm_resource_group.rg.name
        virtual_network_name = azurerm_virtual_network.main.name
        address_prefixes     = ["10.0.2.0/24"]
    }

    resource "azurerm_network_interface" "main" {
        name                = "mynic"
        location            = azurerm_resource_group.rg.location
        resource_group_name = azurerm_resource_group.rg.name

        ip_configuration {
            name                          = "testconfiguration1"
            subnet_id                     = azurerm_subnet.internal.id
            private_ip_address_allocation = "Dynamic"
        }
    }

    resource "azurerm_virtual_machine" "main" {
        name                  = "myvm"
        location              = azurerm_resource_group.rg.location
        resource_group_name   = azurerm_resource_group.rg.name
        network_interface_ids = [azurerm_network_interface.main.id]
        vm_size               = "Standard_DS1_v2"

        storage_image_reference {
            publisher = "Canonical"
            offer     = "UbuntuServer"
            sku       = "16.04-LTS"
            version   = "latest"
        }

        storage_os_disk {
            name              = "myosdisk1"
            caching           = "ReadWrite"
            create_option     = "FromImage"
            managed_disk_type = "Standard_LRS"
        }
        os_profile {
            computer_name  = "hostname"
            admin_username = "myselftest"
            admin_password = "Password1234!"
        }
        os_profile_linux_config {
            disable_password_authentication = false
        }
    }
    ```

1. Ready to deploy? Not yet? There is a command for that. Before runnning the `apply` command, you can use `terraform plan` to see what will happen to your resources given the current state and the new configuration:
    ```terraform
    terraform plan
    ```

    You should see the list of resources that will be created:
    ```bash
    sylvain@Azure:~/clouddrive/firstinstance$ terraform plan
    azurerm_resource_group.rg: Refreshing state... [id=/subscriptions/086a6344-054**********cbdea/resourceGroups/myresourcegroup]

    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
    + create

    Terraform will perform the following actions:

    # azurerm_network_interface.main will be created
    + resource "azurerm_network_interface" "main" {
        + applied_dns_servers           = (known after apply)
        + dns_servers                   = (known after apply)
        + enable_accelerated_networking = false
        + enable_ip_forwarding          = false
        + id                            = (known after apply)
        + internal_dns_name_label       = (known after apply)
        + internal_domain_name_suffix   = (known after apply)
        + location                      = "eastus"
        + mac_address                   = (known after apply)
        + name                          = "mynic"
        + private_ip_address            = (known after apply)
        + private_ip_addresses          = (known after apply)
        + resource_group_name           = "myresourcegroup"
        + virtual_machine_id            = (known after apply)

        + ip_configuration {
            + name                          = "testconfiguration1"
            + primary                       = (known after apply)
            + private_ip_address            = (known after apply)
            + private_ip_address_allocation = "dynamic"
            + private_ip_address_version    = "IPv4"
            + subnet_id                     = (known after apply)
            }
        }

    # azurerm_subnet.internal will be created
    + resource "azurerm_subnet" "internal" {
        + address_prefix                                 = (known after apply)
        + address_prefixes                               = [
            + "10.0.2.0/24",
            ]
        + enforce_private_link_endpoint_network_policies = false
        + enforce_private_link_service_network_policies  = false
        + id                                             = (known after apply)
        + name                                           = "internal"
        + resource_group_name                            = "myresourcegroup"
        + virtual_network_name                           = "myvnet"
        }

    # azurerm_virtual_machine.main will be created
    + resource "azurerm_virtual_machine" "main" {
        + availability_set_id              = (known after apply)
        + delete_data_disks_on_termination = false
        + delete_os_disk_on_termination    = false
        + id                               = (known after apply)
        + license_type                     = (known after apply)
        + location                         = "eastus"
        + name                             = "myvm"
        + network_interface_ids            = (known after apply)
        + resource_group_name              = "myresourcegroup"
        + vm_size                          = "Standard_DS1_v2"

        + identity {
            + identity_ids = (known after apply)
            + principal_id = (known after apply)
            + type         = (known after apply)
            }

        + os_profile {
            + admin_password = (sensitive value)
            + admin_username = "myselftest"
            + computer_name  = "hostname"
            + custom_data    = (known after apply)
            }

        + os_profile_linux_config {
            + disable_password_authentication = false
            }

        + storage_data_disk {
            + caching                   = (known after apply)
            + create_option             = (known after apply)
            + disk_size_gb              = (known after apply)
            + lun                       = (known after apply)
            + managed_disk_id           = (known after apply)
            + managed_disk_type         = (known after apply)
            + name                      = (known after apply)
            + vhd_uri                   = (known after apply)
            + write_accelerator_enabled = (known after apply)
            }

        + storage_image_reference {
            + offer     = "UbuntuServer"
            + publisher = "Canonical"
            + sku       = "16.04-LTS"
            + version   = "latest"
            }

        + storage_os_disk {
            + caching                   = "ReadWrite"
            + create_option             = "FromImage"
            + disk_size_gb              = (known after apply)
            + managed_disk_id           = (known after apply)
            + managed_disk_type         = "Standard_LRS"
            + name                      = "myosdisk1"
            + os_type                   = (known after apply)
            + write_accelerator_enabled = false
            }
        }

    # azurerm_virtual_network.main will be created
    + resource "azurerm_virtual_network" "main" {
        + address_space         = [
            + "10.0.0.0/16",
            ]
        + guid                  = (known after apply)
        + id                    = (known after apply)
        + location              = "eastus"
        + name                  = "myvnet"
        + resource_group_name   = "myresourcegroup"
        + subnet                = (known after apply)
        + vm_protection_enabled = false
        }

    Plan: 4 to add, 0 to change, 0 to destroy.
    ```

    You can also use the flag `--out` to save the changes in another file. This is especially usefull if you want to add a validation step inside a CICD pipeline before deploying your new infrastructure on your existing environment. If you use this flag, the next time you run the apply command, this output will be use as the changeset to execute.

1. Now you can apply the changes:
    ```bash
    terraform apply
    ```

    After agreeing to the changes you should see something similar to:
    ```bash
    azurerm_virtual_network.main: Creating...
    azurerm_virtual_network.main: Creation complete after 3s [id=/subscriptions/086a6344-054**********cbdea/resourceGroups/myresourcegroup/providers/Microsoft.Network/virtualNetworks/myvnet]
    azurerm_subnet.internal: Creating...
    azurerm_subnet.internal: Creation complete after 3s [id=/subscriptions/086a6344-054**********cbdea/resourceGroups/myresourcegroup/providers/Microsoft.Network/virtualNetworks/myvnet/subnets/internal]
    azurerm_network_interface.main: Creating...
    azurerm_network_interface.main: Creation complete after 1s [id=/subscriptions/086a6344-054**********cbdea/resourceGroups/myresourcegroup/providers/Microsoft.Network/networkInterfaces/mynic]
    azurerm_virtual_machine.main: Creating...
    azurerm_virtual_machine.main: Still creating... [10s elapsed]
    azurerm_virtual_machine.main: Creation complete after 19s [id=/subscriptions/086a6344-054**********cbdea/resourceGroups/myresourcegroup/providers/Microsoft.Compute/virtualMachines/myvm]
    ```
    
     you can go to the portal a check that you have an ubuntu VM running.

1. After your done, you can remove all the resources by using terraform:
    ```bash
    terraform destroy
    ```

    After you agree, the resource group and all the resources within will be deleted.