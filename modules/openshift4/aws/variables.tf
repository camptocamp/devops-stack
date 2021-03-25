variable "install_config_path" {
    description = "Path of the install-config.yaml"
    type        = string
}

variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
}

variable "region" {
  description = "The AWS region."
  type        = string
}
