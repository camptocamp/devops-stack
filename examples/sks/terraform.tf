terraform {
  # We could store the state file on an Exoscale bucket, but there is no DynamoDB equivalent neither encryption, 
  # as far as I know. See https://github.com/exoscale/terraform-provider-exoscale/tree/master/examples/sos-backend
  backend "s3" {
    encrypt        = true
    bucket         = "<BUCKET_NAME>"
    key            = "<NAME_OF_THE_STATE_FILE>"
    region         = "eu-west-1"
    dynamodb_table = "<DYANMODB_TABLE_NAME>"
  }

  required_providers {
    exoscale = {
      source  = "exoscale/exoscale"
      version = "~> 0.51"
    }
    aws = { # Needed to store the state file in S3 and to create S3 buckets (provider configuration bellow)
      source  = "hashicorp/aws"
      version = "~> 5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2"
    }
    argocd = {
      source  = "oboukili/argocd"
      version = "~> 6"
    }
    keycloak = {
      source  = "mrparkers/keycloak"
      version = "~> 4"
    }
  }
}

provider "aws" {
  endpoints {
    s3 = "https://sos-${local.zone}.exo.io"
  }

  region = local.zone

  access_key = var.exoscale_iam_key
  secret_key = var.exoscale_iam_secret

  # Skip validations specific to AWS in order to use this provider for Exoscale services.
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
}

# The providers configurations below depend on the output of some of the modules declared on other *tf files.
# However, for clarity and ease of maintenance we grouped them all together in this section.

provider "kubernetes" {
  host                   = module.sks.kubernetes_host
  client_certificate     = module.sks.kubernetes_client_certificate
  client_key             = module.sks.kubernetes_client_key
  cluster_ca_certificate = module.sks.kubernetes_cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.sks.kubernetes_host
    client_certificate     = module.sks.kubernetes_client_certificate
    client_key             = module.sks.kubernetes_client_key
    cluster_ca_certificate = module.sks.kubernetes_cluster_ca_certificate
  }
}

provider "argocd" {
  auth_token                  = module.argocd_bootstrap.argocd_auth_token
  port_forward_with_namespace = module.argocd_bootstrap.argocd_namespace
  insecure                    = true
  plain_text                  = true
  kubernetes {
    host                   = module.sks.kubernetes_host
    client_certificate     = module.sks.kubernetes_client_certificate
    client_key             = module.sks.kubernetes_client_key
    cluster_ca_certificate = module.sks.kubernetes_cluster_ca_certificate
  }
}

provider "keycloak" {
  client_id                = "admin-cli"
  username                 = module.keycloak.admin_credentials.username
  password                 = module.keycloak.admin_credentials.password
  url                      = format("https://keycloak.%s.%s", trimprefix("${local.subdomain}.${module.sks.cluster_name}", "."), module.sks.base_domain)
  tls_insecure_skip_verify = true # Can be disabled/removed when using letsencrypt-prod as cluster issuer
  initial_login            = false
}
