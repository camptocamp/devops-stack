terraform {
  required_providers {
    kind = {
      source  = "kyma-incubator/kind"
      version = "~> 0.0.9"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = "~> 2.15.0"
    }
  }
}
