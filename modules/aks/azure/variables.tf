variable "cluster_name" {
  type        = string
}

variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
}

variable "kubernetes_version" {
  description = "Specify which Kubernetes release to use."
  type        = string
  default     = "1.21.2"
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

variable "network_policy" {
  description = "Enable network policy for the azure CNI"
  type        = string
  default     = null
}

variable "node_pools" {
  default     = {}
  description = "List of node pools with minimal configuration"
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
