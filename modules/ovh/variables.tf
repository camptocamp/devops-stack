variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
  default     = null
}

variable "other_domains" {
  description = "Other domains used for Ingresses requiring a DNS-01 challenge for Let's Encrypt validation with cert-manager (e.g. wildcard certificates)."
  type        = list(string)
  default     = []
}

variable "cert_manager_dns01" {
  description = "Ingress block for the htt01 chalenge of cert-manager"
  type        = any
  default     = {}
}

variable "kubernetes_version" {
  description = "Specify which Kubernetes release to use."
  type        = string
  default     = "1.25.4-1"
}

variable "cluster_name" {
  description = "The name of the Kubernetes cluster to create."
  type        = string
}

variable "cluster_region" {
  description = "The region from which we want to create the cluster"
  type        = string
}

variable "cluster_region_name" {
  description = "The region name from which we want to create S3 buckets"
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
