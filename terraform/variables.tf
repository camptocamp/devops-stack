variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
}

variable "kubernetes_version" {
  description = "Specify which Kubernetes release to use."
  type        = string
  default     = "1.21.9"
}

variable "resource_group_name" {
  description = "The Resource Group where the Managed Kubernetes Cluster should exist."
  type        = string
}

variable "vnet_subnet_id" {
  description = "The ID of a Subnet where the Kubernetes Node Pool should exist. Changing this forces a new resource to be created."
  type        = string
}


variable "agents_pool_name" {
  description = "The default Azure AKS agentpool (nodepool) name."
  type        = string
  default     = "nodepool"
}

variable "agents_count" {
  description = "The number of Agents that should exist in the Agent Pool. Please set `agents_count` `null` while `enable_auto_scaling` is `true` to avoid possible `agents_count` changes."
  type        = number
  default     = 2
}

variable "agents_max_pods" {
  description = "(Optional) The maximum number of pods that can run on each agent. Changing this forces a new resource to be created."
  type        = number
  default     = null
}

variable "agents_size" {
  description = "The default virtual machine size for the Kubernetes agents"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "agents_labels" {
  description = "A map of Kubernetes labels which should be applied to nodes in the Default Node Pool. Changing this forces a new resource to be created."
  type        = map(string)
  default     = {}
}

variable "os_disk_size_gb" {
  description = "Disk size of nodes in GBs."
  type        = number
  default     = 128
}

variable "admin_group_object_ids" {
  description = "A list of Object IDs of Azure Active Directory Groups which should have Admin Role on the Cluster."
  type        = list(string)
  default     = []
}

variable "public_ssh_key" {
  description = "A custom ssh key to control access to the AKS cluster"
  type        = string
  default     = ""
}

variable "azureidentities" {
  description = "Azure User Assigned Identities to create"
  type = list(object({
    namespace = string
    name      = string
  }))
  default = []
}

variable "network_policy" {
  description = "Enable network policy for the azure CNI"
  type        = string
  default     = null
}

variable "node_pools" {
  default     = {}
  description = "Map of node pools"
  type        = map(any)
}

variable "storage_account_tier" {
  description = "Storage account tier used for storing loki logs"
  default     = "Standard"
  type        = string
}

variable "storage_account_replication_type" {
  description = "Storage account replication type for storing loki logs"
  default     = "GRS"
  type        = string
}

variable "sku_tier" {
  description = "The SKU Tier that should be used for this Kubernetes Cluster. Possible values are Free and Paid"
  default     = "Free"
  type        = string
}

variable "app_node_selectors" {
  /* Example:
  app_node_selectors = {
    aad-pod-identity = {
      "kubernetes.azure.com/agentpool" = "default"
    }
    argocd = {
      "odoo.camptocamp.io/nodepool"    = "mutualized"
      "odoo.camptocamp.io/environment" = "prod"
    }
    non-existing-app = {
      "odoo.camptocamp.io/nodepool"    = "mutualized"
      "odoo.camptocamp.io/environment" = "misc-apps"
    }
    kube-prometheus-stack = {
      "kubernetes.azure.com/agentpool" = "default"
    }
    loki-stack = {}
    #cert-manager = {}
  }
*/
  description = "Map of argoCD apps to node selector"
  default     = {}
  type        = map(map(string))
}
# commenting for compat
#variable "kubeconfig" {
#  description = "The content of the KUBECONFIG file."
#  type        = string
#}

variable "repo_url" {
  description = "The source repo URL of ArgoCD's app of apps."
  type        = string
}

variable "target_revision" {
  description = "The source target revision of ArgoCD's app of apps."
  type        = string
}

variable "extra_apps" {
  description = "Extra Applications objects to deploy."
  type        = any
  default     = []
}

variable "extra_app_projects" {
  description = "Extra AppProjects objects to deploy."
  type        = any
  default     = []
}

variable "extra_application_sets" {
  description = "Extra ApplicationSets objects to deploy."
  type        = any
  default     = []
}

variable "argocd_server_secretkey" {
  description = "ArgoCD Server Secert Key to avoid regenerate token on redeploy."
  type        = string
  default     = null
}

variable "cluster_name" {
  description = "The name of the cluster to create."
  type        = string
}

# variable "base_domain" {
#   description = "The base domain used for Ingresses."
#   type        = string
# }

variable "cluster_issuer" {
  description = "Cluster Issuer"
  type        = string
}

variable "oidc" {
  description = "OIDC Settings"
  type        = any
  default     = {}
}

variable "argocd" {
  description = "ArgoCD settings"
  type        = any
  default     = {}
}

variable "grafana" {
  description = "Grafana settings"
  type        = any
  default     = {}
}

variable "prometheus" {
  description = "Prometheus settings"
  type        = any
  default     = {}
}

variable "alertmanager" {
  description = "Alertmanager settings"
  type        = any
  default     = {}
}

variable "loki" {
  description = "Loki settings"
  type        = any
  default     = {}
}

variable "traefik" {
  description = "Trafik settings"
  type        = any
  default     = {}
}

variable "keycloak" {
  description = "Keycloak settings"
  type        = any
  default     = {}
}

variable "minio" {
  description = "Minio settings"
  type        = any
  default     = {}
}

variable "app_of_apps_values_overrides" {
  description = "Extra value files content for the App of Apps"
  type        = list(string)
  default     = []
}

variable "metrics_server" {
  description = "Metrics server settings"
  type        = any
  default     = {}
}

variable "metrics_archives" {
  description = "Metrics archives settings"
  type        = any
  default     = {}
}

variable "cert_manager" {
  description = "Cert Manager settings"
  type        = any
  default     = {}
}

variable "kube_prometheus_stack" {
  description = "Kube-prometheus-stack settings"
  type        = any
  default     = {}
}

variable "cluster_autoscaler" {
  description = "Cluster Autoscaler settings"
  type        = any
  default     = {}
}

variable "wait_for_app_of_apps" {
  description = "Allow to disable wait for app of apps"
  type        = bool
  default     = true
}

variable "repositories" {
  description = "A list of repositories to add to ArgoCD."
  type        = map(map(string))
  default     = {}
}
