module "cluster" {
  source = "git::https://github.com/qalita-io/devops-stack.git//modules/ovh?ref=ovh"

  cluster_name   = format("%s-%s", local.cluster_prefix, local.cluster_name)
  base_domain    = local.base_domain
  cluster_region = local.cluster_datacenter

  flavor_name   = local.cluster_flavor_name
  desired_nodes = local.cluster_desired_nodes
  max_nodes     = local.cluster_max_nodes
  min_nodes     = local.cluster_min_nodes
}

module "argocd_bootstrap" {
  source     = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=v3.1.3"
  depends_on = [module.cluster]
}

resource "null_resource" "install_crds" {
  # Only run if local.enable_service_monitor is true
  count = local.enable_service_monitor ? 1 : 0

  # Use the local-exec provisioner to run Helm commands
  provisioner "local-exec" {
    command = <<EOT
      kubectl config set-cluster terraform-cluster --server=${local.kubernetes_host} --certificate-authority=${local.kubernetes_cluster_ca_certificate}
      kubectl config set-credentials terraform-user --client-certificate=${local.kubernetes_client_certificate} --client-key=${local.kubernetes_client_key}
      kubectl config set-context terraform --cluster=terraform-cluster --user=terraform-user
      kubectl config use-context terraform
      helm upgrade --install prometheus-operator-crds https://github.com/prometheus-community/helm-charts/releases/download/prometheus-operator-crds-5.1.0/prometheus-operator-crds-5.1.0.tgz || true
    EOT
  }

  # Always run this provisioner
  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [module.cluster]
}

module "traefik" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//kind?ref=v2.0.1"

  cluster_name           = local.cluster_name
  base_domain            = local.base_domain
  argocd_namespace       = module.argocd_bootstrap.argocd_namespace
  enable_service_monitor = local.enable_service_monitor
  depends_on             = [module.cluster, null_resource.install_crds]
  helm_values = [{
    traefik = {
      ports = {
        web = {
          redirectTo = "websecure"
        },
        websecure = {
          tls = {
            enabled = true
          }
        }
      }
    }
  }]
}

data "kubernetes_service" "traefik" {
  metadata {
    name      = "traefik"
    namespace = "traefik"
  }
  depends_on = [module.traefik.id]
}


# Add A record to domain
resource "ovh_domain_zone_record" "root_domain_record" {
  zone       = local.domaine_zone_name
  subdomain  = ""
  fieldtype  = "A"
  ttl        = 3600
  target     = data.kubernetes_service.traefik.status.0.load_balancer.0.ingress.0.ip
  depends_on = [module.cluster]
}

# Add a record to a sub-domain
resource "ovh_domain_zone_record" "wildcard_record" {
  zone       = local.domaine_zone_name
  subdomain  = "*"
  fieldtype  = "A"
  ttl        = 3600
  target     = data.kubernetes_service.traefik.status.0.load_balancer.0.ingress.0.ip
  depends_on = [module.traefik.id]
}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager?ref=v5.1.0"

  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  enable_service_monitor = local.enable_service_monitor

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
    argocd  = module.argocd_bootstrap.id
    traefik = module.traefik.id
  }
}

module "keycloak" {
  source = "git::https://github.com/qalita-io/devops-stack-module-keycloak?ref=v2.0.8"

  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  target_revision  = "v2.0.8"

  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
  }

  helm_values = [{
    keycloak = {
      pvc = {
        enabled = true
      }
    }
  }]
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-keycloak//oidc_bootstrap?ref=v2.0.1"

  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  cluster_issuer = local.cluster_issuer

  dependency_ids = {
    keycloak = module.keycloak.id
  }
}

module "thanos" {
  source = "git::https://github.com/camptocamp/devops-stack-module-thanos//kind?ref=v2.1.0"

  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  metrics_storage = {
    bucket_name = aws_s3_bucket.thanos_bucket.bucket
    endpoint    = var.s3_endpoint
    access_key  = ovh_cloud_project_user_s3_credential.thanos_write_cred.access_key_id
    secret_key  = ovh_cloud_project_user_s3_credential.thanos_write_cred.secret_access_key
    insecure    = false
  }

  thanos = {
    oidc = module.oidc.oidc
  }

  dependency_ids = {
    argocd       = module.argocd_bootstrap.id
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    keycloak     = module.keycloak.id
    oidc         = module.oidc.id
  }
}

module "kube-prometheus-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack//kind?ref=v6.1.0"

  cluster_name     = local.cluster_name
  base_domain      = local.base_domain
  cluster_issuer   = local.cluster_issuer
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  metrics_storage = {
    bucket_name = aws_s3_bucket.thanos_bucket.bucket
    endpoint    = var.s3_endpoint
    access_key  = ovh_cloud_project_user_s3_credential.thanos_write_cred.access_key_id
    secret_key  = ovh_cloud_project_user_s3_credential.thanos_write_cred.secret_access_key
    insecure    = false
  }

  prometheus = {
    oidc = module.oidc.oidc
  }
  alertmanager = {
    oidc = module.oidc.oidc
  }
  grafana = {
    oidc = module.oidc.oidc
  }

  dependency_ids = {
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    oidc         = module.oidc.id
  }
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git?ref=v3.1.3"

  base_domain              = local.base_domain
  cluster_name             = local.cluster_name
  cluster_issuer           = local.cluster_issuer
  admin_enabled            = "true"
  server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey
  namespace                = module.argocd_bootstrap.argocd_namespace
  accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens

  oidc = {
    name         = "OIDC"
    issuer       = module.oidc.oidc.issuer_url
    clientID     = module.oidc.oidc.client_id
    clientSecret = module.oidc.oidc.client_secret
    requestedIDTokenClaims = {
      groups = {
        essential = true
      }
    }
  }

  dependency_ids = {
    argocd                = module.argocd_bootstrap.id
    traefik               = module.traefik.id
    cert-manager          = module.cert-manager.id
    oidc                  = module.oidc.id
    kube-prometheus-stack = module.kube-prometheus-stack.id
  }
}


module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack//kind?ref=v4.0.2"

  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  distributed_mode = false

  logs_storage = {
    bucket_name = aws_s3_bucket.loki_bucket.bucket
    access_key  = ovh_cloud_project_user_s3_credential.loki_write_cred.access_key_id
    secret_key  = ovh_cloud_project_user_s3_credential.loki_write_cred.secret_access_key
    endpoint    = var.s3_endpoint
    insecure    = false
  }

  dependency_ids = {
    argocd = module.argocd.id
  }
}


module "metrics_server" {
  source = "git::https://github.com/camptocamp/devops-stack-module-application.git?ref=v2.0.1"

  name             = "metrics-server"
  argocd_namespace = module.argocd_bootstrap.argocd_namespace

  source_repo            = "https://github.com/kubernetes-sigs/metrics-server.git"
  source_repo_path       = "charts/metrics-server"
  source_target_revision = "metrics-server-helm-chart-3.8.3"
  destination_namespace  = "kube-system"
  helm_values = [{
    metrics-server = {
      args = [
        "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"
      ]
    }
  }]

  dependency_ids = {
    argocd = module.argocd.id
  }
}
