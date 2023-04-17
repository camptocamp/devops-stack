locals {
  cluster_name   = "kind-cluster"
  cluster_issuer = "ca-issuer"
}

# Step 1: deploy k8s cluster
module "kind" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cluster-kind.git?ref=v2.1.0"

  cluster_name       = local.cluster_name
  kubernetes_version = "v1.24.7"
}

provider "kubernetes" {
  host               = module.kind.parsed_kubeconfig.host
  client_certificate = module.kind.parsed_kubeconfig.client_certificate
  client_key         = module.kind.parsed_kubeconfig.client_key
  insecure           = true
}

provider "helm" {
  kubernetes {
    host               = module.kind.parsed_kubeconfig.host
    client_certificate = module.kind.parsed_kubeconfig.client_certificate
    client_key         = module.kind.parsed_kubeconfig.client_key
    insecure           = true
  }
}

# Step 2: deploy metallb, argocd_bootstrap, traefik, cert-manager & keycloak
module "metallb" {
  source = "git::https://github.com/camptocamp/devops-stack-module-metallb.git?ref=v1.0.1"

  subnet = module.kind.kind_subnet
}

module "argocd_bootstrap" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=v1.1.0"
}

provider "argocd" {
  server_addr                 = "127.0.0.1:8080"
  auth_token                  = module.argocd_bootstrap.argocd_auth_token
  insecure                    = true
  plain_text                  = true
  port_forward                = true
  port_forward_with_namespace = module.argocd_bootstrap.argocd_namespace
  kubernetes {
    host                   = module.kind.parsed_kubeconfig.host
    client_certificate     = module.kind.parsed_kubeconfig.client_certificate
    client_key             = module.kind.parsed_kubeconfig.client_key
    cluster_ca_certificate = module.kind.parsed_kubeconfig.cluster_ca_certificate
  }
}

module "traefik" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//kind?ref=v1.0.0"

  cluster_name     = local.cluster_name
  base_domain      = "remove"
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//self-signed?ref=v2.0.0"

  cluster_name     = "remove"
  base_domain      = "remove"
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
}

# TBD - Minio module

# TBD - Loki module

module "keycloak" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak?ref=v1.0.2"

  cluster_name     = local.cluster_name
  base_domain      = format("%s.nip.io", replace(module.traefik.external_ip, ".", "-"))
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
  }
}

provider "keycloak" {
  client_id                = "admin-cli"
  username                 = module.keycloak.admin_credentials.username
  password                 = module.keycloak.admin_credentials.password
  url                      = "https://keycloak.apps.${local.cluster_name}.${format("%s.nip.io", replace(module.traefik.external_ip, ".", "-"))}"
  tls_insecure_skip_verify = true
}

# Step 3: provision keyclaok & deploy kube-prometheus-stack & argocd
module "keycloak-config" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak//oidc_bootstrap?ref=v1.0.2"

  cluster_name   = local.cluster_name
  base_domain    = format("%s.nip.io", replace(module.traefik.external_ip, ".", "-"))
  cluster_issuer = local.cluster_issuer

  dependency_ids = {
    keycloak = module.keycloak.id
  }
}

# TBD - Thanos module

module "kube-prometheus-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack//kind?ref=v2.0.0"

  cluster_name     = local.cluster_name
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  base_domain      = format("%s.nip.io", replace(module.traefik.external_ip, ".", "-"))
  cluster_issuer   = local.cluster_issuer

  prometheus = {
    oidc = module.keycloak-config.oidc
  }
  alertmanager = {
    oidc = module.keycloak-config.oidc
  }
  grafana = {
    enabled                 = true
    oidc                    = module.keycloak-config.oidc
    additional_data_sources = true
  }

  helm_values = [{
    kube-prometheus-stack = {
      grafana = {
        extraSecretMounts = [
          {
            name       = "ca-certificate"
            secretName = "grafana-tls"
            mountPath  = "/etc/ssl/certs/ca.crt"
            readOnly   = true
            subPath    = "ca.crt"
          },
        ]
      }
    }
  }]

  dependency_ids = {
    keycloak-config = module.keycloak-config.id
    cert-manager    = module.cert-manager.id
  }
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git?ref=v1.1.0"

  base_domain              = format("%s.nip.io", replace(module.traefik.external_ip, ".", "-"))
  cluster_name             = local.cluster_name
  cluster_issuer           = local.cluster_issuer
  server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
  accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens

  oidc = {
    name         = "OIDC"
    issuer       = module.keycloak-config.oidc.issuer_url
    clientID     = module.keycloak-config.oidc.client_id
    clientSecret = module.keycloak-config.oidc.client_secret
    requestedIDTokenClaims = {
      groups = {
        essential = true
      }
    }
  }

  helm_values = [{
    argo-cd = {
      configs = {
        rbac = {
          "scopes"     = "[groups]"
          "policy.csv" = <<-EOT
            g, pipeline, role:admin
            g, devops-stack-admins, role:admin
          EOT
        }
      }
    }
  }]

  dependency_ids = {
    keycloak-config       = module.keycloak-config.id
    kube-prometheus-stack = module.kube-prometheus-stack.id
  }
}
