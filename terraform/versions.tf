terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "2.3.0"
    }
    docker = {
      source = "terraform-providers/docker"
    }
  }
  required_version = ">= 0.13"
}
