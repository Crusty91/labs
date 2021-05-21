variable "routing_policy" {
                default = "Weighted"
            }
            
            variable "rgname" {
                default = "myrg"
            }

            variable "prefix" {
                default = "webapp"
            }

            variable "region" {
                default = "eastus"
            }

            variable "target_blue" {}

            variable "target_green" {}
