# Nomenclature:
# BM: Before merge
# Q: open question

# -------
# BM review dependency_ids of all modules
# TODO add repo_url / chart_path variables to all modules with argocd apps: helps with chart dev.

locals {
  cluster_name   = "kind"
  cluster_issuer = "ca-issuer"
}

module "kind" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cluster-kind.git?ref=new-setup"

  cluster_name       = local.cluster_name
  kubernetes_version = "v1.24.7"
}

provider "kubernetes" {
  host                   = module.kind.parsed_kubeconfig.host
  client_certificate     = module.kind.parsed_kubeconfig.client_certificate
  client_key             = module.kind.parsed_kubeconfig.client_key
  cluster_ca_certificate = module.kind.parsed_kubeconfig.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host               = module.kind.parsed_kubeconfig.host
    client_certificate = module.kind.parsed_kubeconfig.client_certificate
    client_key         = module.kind.parsed_kubeconfig.client_key
    insecure           = true
  }
}

module "metallb" {
  source = "git::https://github.com/camptocamp/devops-stack-module-metallb.git?ref=v1.0.0-alpha.1"

  subnet = module.kind.kind_subnet
}

module "argocd_bootstrap" {
  # TODO point at c2c repo and change ref once "bootstrap_minimal" is merged.
  # Q: is argo_namespace output needed ?
  source = "git::https://github.com/modridi/devops-stack-module-argocd.git//bootstrap?ref=bootstrap_minimal"
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

# TODO restore nodeport submodule and create temporary new submodule for kind.
module "ingress" {
  source          = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//kind?ref=refactor-local-module"
  target_revision = "refactor-local-module"

  cluster_name = local.cluster_name

  # TODO fix: the base domain is defined later. Proposal: remove redirection from traefik module and add it in dependent modules.
  # For now random value is passed to base_domain. Redirections will not work before fix.
  base_domain = "something.com"

  argocd_namespace = module.argocd_bootstrap.argocd_namespace
}

module "cert-manager" {
  # TODO remove useless base_domain and cluster_name variables from "self-signed" module.
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//self-signed?ref=v1.0.0-alpha.3"

  cluster_name     = local.cluster_name
  base_domain      = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
}

module "oidc" {
  # NOTE: realm export doesn't export users.
  # TODO client secret must be generated and passed as helm value if realm import CRD will be used.
  source          = "git::https://github.com/camptocamp/devops-stack-module-keycloak.git?ref=keycloak-refactor"
  target_revision = "keycloak-refactor"

  cluster_name     = local.cluster_name
  base_domain      = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  dependency_ids = {
    traefik      = module.ingress.id
    cert-manager = module.cert-manager.id
  }
}

# module "minio" {}

# module "thanos" {}

# module "loki-stack" {}

# module "prometheus-stack" {
#   source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//kind?ref=fix-secret-dependency"
#   target_revision = "fix-secret-dependency"

#   cluster_name     = local.cluster_name
#   argocd_namespace = module.argocd_bootstrap.argocd_namespace
#   base_domain      = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
#   cluster_issuer   = local.cluster_issuer

#   # metrics_storage = {}

#   # TODO conditional oidc activation for all 3 components.
#   prometheus = {
#     oidc = module.oidc.oidc
#   }
#   alertmanager = {
#     oidc = module.oidc.oidc
#   }
#   grafana = {
#     enabled                 = true
#     oidc                    = module.oidc.oidc
#     additional_data_sources = true
#   }
# }

#   # Grafana server can't validate Keycloak's certificate. Following is a temporary workaround.
#   # TODO fix this. Maybe a way to disable cert validation. If there is no way, add this config conditionally to module.
#   helm_values = [{
#     kube-prometheus-stack = {
#       grafana = {
#         extraSecretMounts = [
#           {
#             name       = "ca-certificate"
#             secretName = "grafana-tls"
#             mountPath  = "/etc/ssl/certs/ca.crt"
#             readOnly   = true
#             subPath    = "ca.crt"
#           },
#         ]
#       }
#     }
#   }]

#   # dependency_ids = {
#   #   keycloak     = module.oid.id
#   #   loki-stack   = module.loki-stack.id
#   #   cert-manager = module.cert-manager.id
#   # }
# }

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git"

  base_domain    = format("%s.nip.io", replace(module.ingress.external_ip, ".", "-"))
  cluster_name   = local.cluster_name
  cluster_issuer = local.cluster_issuer

  argocd = {
    admin_enabled            = "true"
    domain                   = format("argocd.apps.%s.%s", local.cluster_name, format("%s.nip.io", replace(module.ingress.external_ip, ".", "-")))
    namespace                = module.argocd_bootstrap.argocd_namespace
    accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens
    server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
  }

  # NOTE: obsolete oidc values. Real values will depend on how realm & co will be created.
  oidc = {
    name = "OIDC"
    # issuer       = module.oidc.oidc.issuer_url
    issuer = "https://keycloak.apps.kind.172-18-0-100.nip.io/realms/demo"
    # clientID     = module.oidc.oidc.client_id
    clientID = "argocd-client"
    # clientSecret = module.oidc.oidc.client_secret
    clientSecret = "W4Z6tcDCb1LAe47jjStihlN3pgZPsO1A"
    requestedIDTokenClaims = {
      groups = {
        essential = true
      }
    }
  }

  helm_values = [{
    argo-cd = {
      # BM remove metrics blocks: controller, repoServer and server
      controller = {
        metrics = {
          enabled = false
        }
      }
      repoServer = {
        metrics = {
          enabled = false
        }
      }
      # TODO same thing as Grafana.
      server = {
        metrics = {
          enabled = false
        }
        volumeMounts = [
          {
            name      = "certificate"
            mountPath = "/etc/ssl/certs/ca.crt"
            subPath   = "ca.crt"
          }
        ]
        volumes = [
          {
            name = "certificate"
            secret = {
              secretName = "argocd-tls"
            }
          }
        ]
      }
      configs = {
        # TODO consider adding jdoe user to a group w/ admin privelege.
        # Related to Keycloak refactoring
        rbac = {
          "scopes"     = "[groups]"
          "policy.csv" = <<-EOT
            g, pipeline, role:admin
            g, platform-team, role:admin
            EOT
        }
      }
    }
  }]
}
