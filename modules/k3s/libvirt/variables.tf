variable "k3os_version" {
  description = "The K3os version to use"
  type        = string
  default     = "v0.20.7-k3s1r0"
}

variable "node_count" {
  description = "Number of nodes to deploy"
  type        = number
  default     = 2
}

variable "server_memory" {
  description = "Server RAM"
  type        = number
  default     = 2048
}

variable "agent_memory" {
  description = "Agent RAM"
  type        = number
  default     = 2048
}
