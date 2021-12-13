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
  description = <<-EOF
    A list of nodes pools to be provisioned for the cluster.
    Each node_pool should include at least a `name` key.
    See [provider documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/kubernetes_cluster_node_pool) for allowed

    Example:

    ```
    node_pools = [
      {
        name       = "infra"
        node_count = 1
      },
      {
        name       = "prod"
        node_count = 2
      },
      {
        name       = "int"
        node_count = 1
      }
    ]
    ```

  EOF
  type = list(any)
  default = []
}
