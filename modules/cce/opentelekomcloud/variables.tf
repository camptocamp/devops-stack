variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
}

variable "flavor_id" {
  description = "Cluster specifications."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC used to create the node."
  type        = string
}

variable "subnet_id" {
  description = "The VPC Subnet ID"
  type        = string
}

variable "network_id" {
  description = "The Network ID of the subnet used to create the node."
  type        = string
}

variable "cluster_version" {
  description = "The K8s version to use."
  type        = string
  default     = "v1.19.8-r0"
}

variable "keycloak_users" {
  description = "List of keycloak users"
  type        = map(map(string))
  default = {}
}

variable "node_pools" {
  description = <<-EOT
    A list of nodes pools to be provisioned for the cluster.
    Each node_pool should include at least a `name` key.

    Example:

    ```
    node_pools = [
      {
        name = infra
      },
      {
        name = prod
      },
      {
        name = int
      }
    ]
    ```
  EOT
  type = list(any)
  default = []
}
