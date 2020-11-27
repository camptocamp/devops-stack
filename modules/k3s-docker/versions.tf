terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.0.0"
    }
    docker = {
      source  = "terraform-providers/docker"
      version = "2.7.2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.13.2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "1.3.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.0.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.0.0"
    }
  }
  required_version = ">= 0.13"
}
