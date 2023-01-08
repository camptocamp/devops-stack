variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
  default     = null
}

variable "keycloak_users" {
  description = "List of keycloak users"
  type        = map(map(string))
  default = {
    jdoe = {
      name       = "Doe"
      first_name = "John"
      email      = "jdoe@example.com"
    }
  }
}

variable "cluster_name" {
  description = "The name of the Kubernetes cluster to create."
  type        = string
}

variable "cluster_region" {
  description = "The region from which we want to create the cluster"
  type        = string
}

variable "flavor_name" {
  description = "The type of instance for the nodepool"
  type        = string
}

variable "desired_nodes" {
  description = "The number of node we want"
  type        = number
}

variable "max_nodes" {
  description = "The number of node we want at maximum"
  type        = number
}

variable "min_nodes" {
  description = "The number of node we want at minimum"
  type        = number
}
