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
