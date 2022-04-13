locals {
  base_domain                       = var.base_domain
  kubernetes_host                   = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.host
  kubernetes_username               = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.username
  kubernetes_password               = data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.password
  kubernetes_client_certificate     = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_certificate)
  kubernetes_client_key             = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.client_key)
  kubernetes_cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.cluster.kube_admin_config.0.cluster_ca_certificate)

  kubeconfig           = data.azurerm_kubernetes_cluster.cluster.kube_admin_config_raw
}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

data "azurerm_kubernetes_cluster" "cluster" {
  # Get name dynamically from cluster_id to set soft dependency on cluster creation
  name                = element(reverse(split("/", module.cluster.aks_id)), 0)
  resource_group_name = data.azurerm_resource_group.this.name
}

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
  agents_labels       = var.agents_labels
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
  node_labels         = lookup(each.value, "node_labels", null)
  mode                = lookup(each.value, "mode", null)
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

data "azurerm_dns_zone" "this" {
  name                = var.base_domain
  resource_group_name = var.resource_group_name
}

data "azurerm_client_config" "current" {}


data "azurerm_policy_set_definition" "restricted" {
  display_name = "Kubernetes cluster pod security restricted standards for Linux-based workloads"
}

data "azurerm_policy_set_definition" "baseline" {
  display_name = "Kubernetes cluster pod security baseline standards for Linux-based workloads"
}

resource "azurerm_policy_assignment" "baseline" {
  name                 = "${var.cluster_name}-baseline"
  scope                = format("%s/resourcegroups/%s", data.azurerm_subscription.primary.id, data.azurerm_resource_group.this.name)
  policy_definition_id = data.azurerm_policy_set_definition.baseline.id
  parameters           = <<PARAMETERS
{
  "effect": {
    "value": "deny"
  },
  "excludedNamespaces": {
    "value": [
      "aad-pod-identity",
      "kube-prometheus-stack",
      "loki-stack",
      "csi-secrets-store-provider-azure",
      "kube-system",
      "gatekeeper-system",
      "azure-arc,aad-pod-identity"
    ]
  }
}
PARAMETERS

}
