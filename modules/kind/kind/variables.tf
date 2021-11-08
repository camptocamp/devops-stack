variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
  default     = null
}

variable "api_server_address" {
  description = "The address to run the Kubernetes API"
  type        = string
  default     = "127.0.0.1"
}

variable "enable_minio" {
  description = "Whether to enable minio object storage system"
  type        = bool
  default     = true
}
