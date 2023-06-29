terraform {
  required_providers {
    ovh = {
      source  = "ovh/ovh"
      version = "~> 0.31.0"
    }
  }
}

provider "ovh" {}

locals {
  service_name = "2829b56e82804f0c8acaab6521f17694"
}

data "ovh_ip_service" "myip" {
  service_name = local.service_name
}

output "id" {
  value = data.ovh_ip_service.myip
}
