variable "k3s_version" {
  description = "The K3s version to use"
  type        = string
  default     = "v1.20.10-k3s1"
}

variable "server_ports" {
  description = "Port mappings of the server container."
  default     = []

  type = set(object({
    internal = number
    external = optional(number)
    ip       = optional(string)
    protocol = optional(string)
  }))
}

variable "cluster_endpoint" {
  description = "The api endpoint, when empty it's the container's IP."
  type        = string
  default     = null
}
