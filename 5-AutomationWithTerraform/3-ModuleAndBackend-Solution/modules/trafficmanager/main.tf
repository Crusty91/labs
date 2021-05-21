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
