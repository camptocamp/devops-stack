locals {
  cluster_name   = "scaleway-test"
  cluster_region = "fr-par"
  cluster_zone   = "fr-par-1"
  tags           = ["test", "${local.cluster_name}"]
}

module "cluster" {
  source = "git::https://github.com/camptocamp/devops-stack.git//modules/scaleway?ref=v1-alpha"

  kubernetes_version = "1.24.3"

  cluster_type = "kapsule"
  cluster_name = local.cluster_name
  cluster_tags = local.tags
  region       = local.cluster_region
  zone         = local.cluster_zone
  lb_type      = "LB-S"

}


module "argocd_bootstrap" {
  source         = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=v1-alpha"
  cluster_name   = local.cluster_name
  base_domain    = module.cluster.base_domain
  cluster_issuer = "letsencrypt-prod"

  argocd = {
    admin_enabled = "true"
  }

  depends_on = [
    module.cluster,
  ]
}


module "ingress" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//scaleway?ref=v1-alpha"

  cluster_name     = local.cluster_name
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  base_domain      = module.cluster.base_domain

  helm_values = [{
    traefik = {
      service = {
        type = "LoadBalancer"
        annotations = {
          "service.beta.kubernetes.io/scw-loadbalancer-id" = module.cluster.lb_id
        }
      }
    }
  }]

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//scaleway?ref=remove-read-only-attribut"

  cluster_name     = local.cluster_name
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  base_domain      = module.cluster.base_domain

  helm_values = [{
    cert-manager = {
      clusterIssuers = {
        letsencrypt = {
          enabled = true
        }
        acme = {
          solvers = [
            {
              http01 = {
                ingress = {}
              }
            }
          ]
        }
      }
    }
  }]

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git?ref=v1-alpha"

  bootstrap_values = module.argocd_bootstrap.bootstrap_values
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  oidc = {}

  helm_values = [{
    argo-cd = {
      global = {
        image = {
          repository = "camptocamp/argocd"
          tag        = "v2.3.4_c2c.3"
        }
      }
      server = {
        config = {
          configManagementPlugins = <<-EOT
                - name: kustomized-helm
                  init:
                    command: ["/bin/sh", "-c"]
                    args: ["helm dependency build || true"]
                  generate:
                    command: ["/bin/sh", "-c"]
                    args: ["echo \"$HELM_VALUES\" | helm template . --name-template $ARGOCD_APP_NAME --namespace $ARGOCD_APP_NAMESPACE $HELM_ARGS -f - --include-crds > all.yaml && kustomize build"]
                - name: helmfile
                  init:
                    command: ["argocd-helmfile"]
                    args: ["init"]
                  generate:
                    command: ["argocd-helmfile"]
                    args: ["generate"]
                  lockRepo: true
          EOT
        }
      }
    }
  }]

  dependency_ids = {
    argocd       = module.argocd_bootstrap.id
    cert_manager = module.cert-manager.id
  }
}

#module "monitoring" {
#  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git?ref=v1-alpha"
#
#  cluster_name = local.cluster_name
#
#  prometheus = {
#    oidc = {
#      issuer_url    = module.oidc.issuer_url
#      api_url       = "${module.oidc.issuer_url}/healthz"
#      client_id     = module.oidc.clients.prometheus.id
#      client_secret = module.oidc.clients.prometheus.secret
#
#      oauth2_proxy_extra_args = [
#      ]
#    }
#  }
#
#  alertmanager = {
#    oidc = {
#      issuer_url    = module.oidc.issuer_url
#      api_url       = "${module.oidc.issuer_url}/healthz"
#      client_id     = module.oidc.clients.alertmanager.id
#      client_secret = module.oidc.clients.alertmanager.secret
#
#      oauth2_proxy_extra_args = [
#      ]
#    }
#  }
#
#  grafana = {
#    oidc = {
#      oauth_url     = "${module.oidc.issuer_url}/auth"
#      token_url     = "${module.oidc.issuer_url}/token"
#      api_url       = "${module.oidc.issuer_url}/userinfo"
#      client_id     = module.oidc.clients.grafana.id
#      client_secret = module.oidc.clients.grafana.secret
#
#      oauth2_proxy_extra_args = [
#      ]
#    }
#  }
#
#  argocd_namespace = module.argocd_bootstrap.argocd_namespace
#  base_domain      = module.cluster.base_domain
#  cluster_issuer   = "letsencrypt-prod"
#  metrics_archives = {}
#
#  dependency_ids = {
#    argocd = module.argocd_bootstrap.id
#    oidc   = module.oidc.id
#  }
#}
