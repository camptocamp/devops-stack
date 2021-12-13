variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Specify which Kubernetes release to use."
  type        = string
  default     = "1.21.6"
}

variable "zone" {
  description = "The name of the zone to deploy the SKS cluster into."
  type        = string
}

variable "keycloak_users" {
  description = "List of keycloak users"
  type        = map(map(string))
  default = {}
}

variable "node_pools" {
    description = <<-EOF
    A list of nodes pools to be provisioned for the cluster.
    Each node_pool should include at least a `name` key.
    Entry node_pools.0, if defined, acts as router_node_pool, else a default one will be created.

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
  EOF
  type = list(any)
  default = []
}
