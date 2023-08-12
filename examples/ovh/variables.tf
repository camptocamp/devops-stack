variable "ENV_FOR_DOMAIN" {
  description = "The environment for domain"
  type        = string
  default     = "dev"
}

variable "CLUSTER_PREFIX" {
  description = "The prefix for cluster"
  type        = string
  default     = "infra"
}

variable "NODE_POOL" {
  description = "value for node pool"
  type        = string
  default     = "c2-7"
}

variable "NODE_POOL_DESIRED_NODES" {
  description = "The number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "NODE_POOL_MAX_NODES" {
  description = "The maximum number of nodes in the node pool"
  type        = number
  default     = 3
}

variable "NODE_POOL_MIN_NODES" {
  description = "The minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "DATACENTER" {
  description = "value for datacenter"
  type        = string
  default     = "GRA9"
}

variable "region" {
  type    = string
  default = "gra"
}

variable "s3_endpoint" {
  type    = string
  default = "s3.gra.io.cloud.ovh.net"
}

variable "OVH_CLOUD_PROJECT_SERVICE" {
  description = "The value for the OVH_CLOUD_PROJECT_SERVICE environment variable"
  type        = string
  default     = ""
}
