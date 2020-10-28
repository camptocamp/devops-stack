terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.8.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "1.13.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.0.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.0.0"
    }
  }

  required_version = ">= 0.13"
}
