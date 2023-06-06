# provider "helm" {
#   kubernetes {
#     host                   = module.cluster.admin_host
#     cluster_ca_certificate = base64decode(module.cluster.admin_cluster_ca_certificate)
#     client_key             = base64decode(module.cluster.admin_client_key)
#     client_certificate     = base64decode(module.cluster.admin_client_certificate)
#     username               = module.cluster.admin_username
#     password               = module.cluster.admin_password
#   }
# }

# provider "kubernetes" {
#   host                   = module.cluster.admin_host
#   cluster_ca_certificate = base64decode(module.cluster.admin_cluster_ca_certificate)
#   client_key             = base64decode(module.cluster.admin_client_key)
#   client_certificate     = base64decode(module.cluster.admin_client_certificate)
#   username               = module.cluster.admin_username
#   password               = module.cluster.admin_password
# }

# module "argocd" {
#   source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=v1.1.0"
# }

# provider "argocd" {
#   server_addr                 = "127.0.0.1:8080"
#   auth_token                  = module.argocd.argocd_auth_token
#   insecure                    = true
#   plain_text                  = true
#   port_forward                = true
#   port_forward_with_namespace = module.argocd.argocd_namespace

#   kubernetes {
#     host                   = module.cluster.admin_host
#     cluster_ca_certificate = base64decode(module.cluster.admin_cluster_ca_certificate)
#     client_key             = base64decode(module.cluster.admin_client_key)
#     client_certificate     = base64decode(module.cluster.admin_client_certificate)
#   }
# }

# module "ingress" {
#   source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//aks?ref=v1.2.1"

#   cluster_name     = local.cluster_name
#   base_domain      = azurerm_dns_zone.this.name
#   argocd_namespace = module.argocd.argocd_namespace

#   enable_service_monitor       = false
#   node_resource_group_name     = module.cluster.node_resource_group
#   dns_zone_resource_group_name = azurerm_resource_group.default.name
# }

# module "azure-workload-identity" {
#   source = "git::https://github.com/camptocamp/devops-stack-module-azure-workload-identity.git?ref=v0.1.0"

#   argocd_namespace = module.argocd.argocd_namespace

#   azure_tenant_id = data.azuread_client_config.current.tenant_id
# }

# module "cert-manager" {
#   source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//aks?ref=v4.0.0"

#   cluster_name     = local.cluster_name
#   base_domain      = azurerm_dns_zone.this.name
#   argocd_namespace = module.argocd.argocd_namespace

#   cluster_oidc_issuer_url      = module.cluster.oidc_issuer_url
#   node_resource_group_name     = module.cluster.node_resource_group
#   dns_zone_resource_group_name = azurerm_resource_group.default.name
#   enable_service_monitor       = false

#   dependency_ids = {
#     azure-workload-identity = module.azure-workload-identity.id
#   }
# }

# module "loki-stack" {
#   source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git//aks?ref=v2.2.0"

#   argocd_namespace = module.argocd.argocd_namespace

#   distributed_mode = true

#   logs_storage = {
#     container                        = azurerm_storage_container.logs.name
#     storage_account                  = azurerm_storage_account.this.name
#     managed_identity_node_rg_name    = module.cluster.node_resource_group
#     managed_identity_oidc_issuer_url = module.cluster.oidc_issuer_url
#   }

#   dependency_ids = {
#     azure-workload-identity = module.azure-workload-identity.id
#   }
# }

# module "thanos" {
#   source = "git::https://github.com/camptocamp/devops-stack-module-thanos.git//aks?ref=v1.0.0"

#   cluster_name     = local.cluster_name
#   base_domain      = azurerm_dns_zone.this.name
#   argocd_namespace = module.argocd.argocd_namespace
#   cluster_issuer   = "letsencrypt-staging"

#   metrics_storage = {
#     container           = azurerm_storage_container.metrics.name
#     storage_account     = azurerm_storage_account.this.name
#     storage_account_key = azurerm_storage_account.this.primary_access_key
#   }

#   thanos = {
#     oidc = local.oidc
#   }

#   dependency_ids = {
#     cert-manager = module.cert-manager.id
#   }
# }

# module "monitoring" {
#   source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//aks?ref=v2.3.0"

#   cluster_name     = local.cluster_name
#   base_domain      = azurerm_dns_zone.this.name
#   argocd_namespace = module.argocd.argocd_namespace
#   cluster_issuer   = "letsencrypt-staging"

#   alertmanager = {
#     oidc = local.oidc
#   }
#   prometheus = {
#     oidc = local.oidc
#   }
#   grafana = {
#     oidc                    = local.oidc
#     additional_data_sources = true
#   }

#   metrics_storage = {
#     container           = azurerm_storage_container.metrics.name
#     storage_account     = azurerm_storage_account.this.name
#     storage_account_key = azurerm_storage_account.this.primary_access_key
#   }

#   dependency_ids = {
#     cert-manager = module.cert-manager.id
#   }
# }

# module "argocd_final" {
#   source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git?ref=v1.1.0"

#   cluster_name   = local.cluster_name
#   base_domain    = azurerm_dns_zone.this.name
#   cluster_issuer = "letsencrypt-staging"

#   admin_enabled            = "true"
#   namespace                = module.argocd.argocd_namespace
#   accounts_pipeline_tokens = module.argocd.argocd_accounts_pipeline_tokens
#   server_secretkey         = module.argocd.argocd_server_secretkey

#   oidc = {
#     name            = "OIDC"
#     issuer          = local.oidc.issuer_url
#     clientID        = local.oidc.client_id
#     clientSecret    = local.oidc.client_secret
#     requestedScopes = ["openid", "profile", "email"]
#     requestedIDTokenClaims = {
#       groups = {
#         essential = true
#       }
#     }
#   }

#   helm_values = [{
#     argo-cd = {
#       configs = {
#         rbac = {
#           "policy.csv" = <<-EOT
#           g, pipeline, role:admin
#           g, argocd-admin, role:admin
#           EOT
#         }
#       }
#     }
#   }]

#   dependency_ids = {
#     kube-prometheus-stack = module.monitoring.id
#     cert-manager          = module.cert-manager.id
#   }
# }
