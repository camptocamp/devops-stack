variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
  default     = null
}

variable "enable_minio" {
  description = "Whether to enable minio object storage system"
  type        = bool
  default     = true
}
