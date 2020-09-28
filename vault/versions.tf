terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "2.3.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "2.14.0"
    }
  }
  required_version = ">= 0.13"
}
