data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azurerm_kubernetes_cluster" "cluster" {
  # Get name dynamically from cluster_id to set soft dependency on cluster creation
  name                = element(reverse(split("/", module.cluster.aks_id)), 0)
  resource_group_name = data.azurerm_resource_group.this.name
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster
# Update to use azure provider
module "cluster" {
  source  = "Azure/aks/azurerm"
  version = "4.13.0"

  kubernetes_version   = var.kubernetes_version
  orchestrator_version = var.kubernetes_version
  sku_tier             = var.sku_tier

  resource_group_name = data.azurerm_resource_group.this.name
  prefix              = var.cluster_name
  network_plugin      = "azure"
  network_policy      = var.network_policy
  vnet_subnet_id      = var.vnet_subnet_id
  agents_pool_name    = var.agents_pool_name
  agents_labels       = merge({ "devops-stack.io/nodepool" = var.agents_pool_name }, var.agents_labels)
  agents_count        = var.agents_count
  agents_size         = var.agents_size
  agents_max_pods     = var.agents_max_pods
  os_disk_size_gb     = var.os_disk_size_gb

  public_ssh_key = var.public_ssh_key

  enable_role_based_access_control = true
  rbac_aad_managed                 = true

  rbac_aad_admin_group_object_ids = var.admin_group_object_ids

  enable_kube_dashboard           = false
  enable_azure_policy             = true
  enable_http_application_routing = false
  enable_log_analytics_workspace  = false
}

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each              = var.node_pools
  name                  = each.key
  kubernetes_cluster_id = module.cluster.aks_id
  vm_size               = each.value.vm_size
  node_count            = each.value.node_count

  availability_zones  = lookup(each.value, "availability_zones", null)
  enable_auto_scaling = lookup(each.value, "enable_auto_scaling", null)
  max_count           = lookup(each.value, "max_count", null)
  min_count           = lookup(each.value, "min_count", null)
  max_pods            = lookup(each.value, "max_pods", null)
  node_taints         = lookup(each.value, "node_taints", null)
  os_disk_size_gb     = lookup(each.value, "os_disk_size_gb", null)
  os_type             = lookup(each.value, "os_type", "Linux")
  vnet_subnet_id      = lookup(each.value, "vnet_subnet_id", var.vnet_subnet_id)
  node_labels         = merge({ "devops-stack.io/nodepool" = each.key }, lookup(each.value, "node_labels", null))
  mode                = lookup(each.value, "mode", null)
}

module "argocd" {
  source = "../../argocd-helm"

  kubeconfig              = local.kubeconfig
  repo_url                = var.repo_url
  target_revision         = var.target_revision
  extra_apps              = var.extra_apps
  extra_app_projects      = var.extra_app_projects
  extra_application_sets  = var.extra_application_sets
  cluster_name            = var.cluster_name
  base_domain             = local.base_domain
  cluster_issuer          = "letsencrypt-prod"
  argocd_server_secretkey = var.argocd_server_secretkey
  wait_for_app_of_apps    = var.wait_for_app_of_apps

  oidc = merge(local.oidc, var.prometheus_oauth2_proxy_args)

  grafana = {
    admin_password = local.grafana_admin_password
  }

  repositories = var.repositories

  app_of_apps_values_overrides = [
    templatefile("${path.module}/values.tmpl.yaml",
      {
        subscription_id                              = split("/", data.azurerm_subscription.primary.id)[2]
        resource_group_name                          = var.resource_group_name
        base_domain                                  = local.base_domain
        cert_manager_resource_id                     = azurerm_user_assigned_identity.cert_manager.id
        cert_manager_client_id                       = azurerm_user_assigned_identity.cert_manager.client_id
        azure_dns_label_name                         = local.azure_dns_label_name
        kube_prometheus_stack_prometheus_resource_id = azurerm_user_assigned_identity.kube_prometheus_stack_prometheus.id
        kube_prometheus_stack_prometheus_client_id   = azurerm_user_assigned_identity.kube_prometheus_stack_prometheus.client_id
        loki_container_name                          = azurerm_storage_container.loki.name
        loki_account_name                            = azurerm_storage_account.this.name
        loki_account_key                             = azurerm_storage_account.this.primary_access_key
        azureidentities                              = local.azureidentities
        namespaces                                   = local.namespaces
      }
    ),
    var.app_of_apps_values_overrides,
  ]

  depends_on = [
    azurerm_kubernetes_cluster_node_pool.this, # node pools creation must precede apps creation for the pod to node assignation
  ]
}

data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "managed_identity_operator" {
  scope                = format("%s/resourcegroups/%s", data.azurerm_subscription.primary.id, module.cluster.node_resource_group)
  role_definition_name = "Managed Identity Operator"
  principal_id         = lookup(module.cluster.kubelet_identity[0], "object_id")
}

resource "azurerm_role_assignment" "virtual_machine_contributor" {
  scope                = format("%s/resourcegroups/%s", data.azurerm_subscription.primary.id, module.cluster.node_resource_group)
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = lookup(module.cluster.kubelet_identity[0], "object_id")
}

resource "azurerm_user_assigned_identity" "kube_prometheus_stack_prometheus" {
  resource_group_name = module.cluster.node_resource_group
  location            = data.azurerm_resource_group.this.location
  name                = "kube-prometheus-stack-prometheus"
}

resource "azurerm_user_assigned_identity" "cert_manager" {
  resource_group_name = module.cluster.node_resource_group
  location            = data.azurerm_resource_group.this.location
  name                = "cert-manager"
}

resource "random_string" "storage_account" {
  length  = 24
  lower   = true
  upper   = false
  special = false
}

resource "azurerm_storage_account" "this" {
  name                     = random_string.storage_account.result
  resource_group_name      = module.cluster.node_resource_group
  location                 = data.azurerm_resource_group.this.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
}

resource "azurerm_storage_container" "loki" {
  name                  = "loki"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}


data "azurerm_dns_zone" "this" {
  name                = var.base_domain
  resource_group_name = var.resource_group_name
}

resource "azurerm_dns_cname_record" "wildcard" {
  name                = "*.apps.${var.cluster_name}"
  zone_name           = data.azurerm_dns_zone.this.name
  resource_group_name = data.azurerm_dns_zone.this.resource_group_name
  ttl                 = 300
  record              = "${local.azure_dns_label_name}.${data.azurerm_resource_group.this.location}.cloudapp.azure.com."
}



