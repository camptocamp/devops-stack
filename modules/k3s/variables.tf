variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
  default     = null
}

variable "node_count" {
  description = "Number of nodes to deploy"
  type        = number
  default     = 2
}

variable "enable_minio" {
  description = "Whether to enable minio object storage system"
  type        = bool
  default     = true
}
