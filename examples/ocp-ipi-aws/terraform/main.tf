locals {
  install_config_path = "install-config.yaml"
  region              = "eu-west-1"
  base_domain         = "example.com"
  cluster_name        = "ocp"
}

provider "aws" {
  region = local.region
}

module "cluster" {
  source              = "git::https://github.com/camptocamp/devops-stack.git//modules/openshift4/aws?ref=v0.35.0"
  install_config_path = local.install_config_path
  base_domain         = local.base_domain
  cluster_name        = local.cluster_name
  region              = local.region
}
