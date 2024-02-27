data "azuread_client_config" "current" {}

data "azurerm_client_config" "current" {}

data "azuread_group" "cluster_admins" {
  object_id = local.cluster_admins_group_object_id
}

resource "azurerm_resource_group" "main" {
  name     = "${local.common_resource_group}-main-rg"
  location = local.location
}

resource "azurerm_virtual_network" "this" {
  name                = "${local.common_resource_group}-vnet"
  resource_group_name = resource.azurerm_resource_group.main.name
  location            = resource.azurerm_resource_group.main.location
  address_space       = [local.virtual_network_cidr]
}

module "aks" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cluster-aks?ref=v1.1.0"

  cluster_name         = local.cluster_name
  base_domain          = local.base_domain
  subdomain            = local.subdomain
  location             = resource.azurerm_resource_group.main.location
  resource_group_name  = resource.azurerm_resource_group.main.name
  virtual_network_name = resource.azurerm_virtual_network.this.name
  cluster_subnet       = local.cluster_subnet

  kubernetes_version = local.kubernetes_version
  sku_tier           = local.sku_tier

  rbac_aad_admin_group_object_ids = [
    data.azuread_group.cluster_admins.object_id
  ]

  # Extra node pools
  node_pools = {
    extra = {
      vm_size    = "Standard_D2s_v3"
      node_count = 2
      node_labels = {
        "devops-stack.io/extra_label" = "extra"
      }
    },
  }

  depends_on = [resource.azurerm_resource_group.main]
}

module "argocd_bootstrap" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=v4.3.0"

  argocd_projects = {
    "${module.aks.cluster_name}" = {
      destination_cluster = "in-cluster"
    }
  }

  depends_on = [module.aks]
}

module "traefik" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//aks?ref=v6.2.0"

  cluster_name   = module.aks.cluster_name
  base_domain    = module.aks.base_domain
  argocd_project = module.aks.cluster_name

  app_autosync           = local.app_autosync
  enable_service_monitor = local.enable_service_monitor

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//aks?ref=v8.1.0"

  cluster_name   = local.cluster_name
  base_domain    = local.base_domain
  argocd_project = module.aks.cluster_name

  letsencrypt_issuer_email     = local.letsencrypt_issuer_email
  cluster_oidc_issuer_url      = module.aks.cluster_oidc_issuer_url
  node_resource_group_name     = module.aks.node_resource_group_name
  dns_zone_resource_group_name = "default"

  app_autosync           = local.app_autosync
  enable_service_monitor = local.enable_service_monitor

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git//aks?ref=v7.0.1"

  argocd_project = module.aks.cluster_name

  app_autosync = local.app_autosync

  logs_storage = {
    container       = resource.azurerm_storage_container.storage["loki"].name
    storage_account = resource.azurerm_storage_account.storage["loki"].name
    # storage_account_key = resource.azurerm_storage_account.storage["loki"].primary_access_key
    managed_identity_node_rg_name    = module.aks.node_resource_group_name
    managed_identity_oidc_issuer_url = module.aks.cluster_oidc_issuer_url
  }

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "thanos" {
  source = "git::https://github.com/camptocamp/devops-stack-module-thanos.git//aks?ref=v4.0.0"

  cluster_name   = module.aks.cluster_name
  base_domain    = module.aks.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer
  argocd_project = module.aks.cluster_name

  app_autosync           = local.app_autosync
  enable_service_monitor = local.enable_service_monitor

  metrics_storage = {
    container       = resource.azurerm_storage_container.storage["thanos"].name
    storage_account = resource.azurerm_storage_account.storage["thanos"].name
    # storage_account_key = resource.azurerm_storage_account.storage["thanos"].primary_access_key
    managed_identity_node_rg_name    = module.aks.node_resource_group_name
    managed_identity_oidc_issuer_url = module.aks.cluster_oidc_issuer_url
  }

  thanos = {
    oidc = local.oidc
  }

  dependency_ids = {
    argocd       = module.argocd_bootstrap.id
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
  }
}

module "kube-prometheus-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//aks?ref=v9.2.1"

  cluster_name   = module.aks.cluster_name
  base_domain    = module.aks.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer
  argocd_project = module.aks.cluster_name

  app_autosync = local.app_autosync

  metrics_storage = {
    container           = resource.azurerm_storage_container.storage["thanos"].name
    storage_account     = resource.azurerm_storage_account.storage["thanos"].name
    storage_account_key = resource.azurerm_storage_account.storage["thanos"].primary_access_key
    # managed_identity_node_rg_name    = module.aks.node_resource_group_name
    # managed_identity_oidc_issuer_url = module.aks.cluster_oidc_issuer_url
  }

  prometheus = {
    oidc = local.oidc
  }

  alertmanager = {
    oidc = local.oidc
  }

  grafana = {
    oidc = local.oidc
  }

  dependency_ids = {
    argocd       = module.argocd_bootstrap.id
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    loki-stack   = module.loki-stack.id
    thanos       = module.thanos.id
  }
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git?ref=v4.3.0"

  cluster_name   = module.aks.cluster_name
  base_domain    = module.aks.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer
  argocd_project = module.aks.cluster_name

  accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens
  server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey

  app_autosync = local.app_autosync

  resources = {}

  high_availability = {
    enabled = false
  }

  admin_enabled = false
  exec_enabled  = true

  oidc = {
    name         = "Entra ID"
    issuer       = local.oidc.issuer_url
    clientID     = local.oidc.client_id
    clientSecret = local.oidc.client_secret
    requestedIDTokenClaims = {
      groups = {
        essential = true
      }
    }
    requestedScopes = [
      "openid", "profile", "email"
    ]
  }

  # Below, add the UUIDs of the groups you want to give admin access to the Argo CD applications.
  rbac = {
    policy_csv = <<-EOT
      g, pipeline, role:admin
      g, ${data.azuread_group.cluster_admins.object_id}, role:admin
    EOT
  }

  dependency_ids = {
    argocd                = module.argocd_bootstrap.id
    traefik               = module.traefik.id
    cert-manager          = module.cert-manager.id
    kube-prometheus-stack = module.kube-prometheus-stack.id
  }
}
