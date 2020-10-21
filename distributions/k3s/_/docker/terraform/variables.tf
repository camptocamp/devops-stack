variable "cluster_name" {
  description = "The name of the Kubernetes cluster to create."
  type        = string
}

variable "k3s_version" {
  description = "The K3s version to use"
  type        = string
  default     = "v1.19.2-k3s1"
}

variable "node_count" {
  description = "Number of nodes to deploy"
  type        = number
  default     = 2
}
