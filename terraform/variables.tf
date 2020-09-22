variable "k3s_kubeconfig_dir" {
  description = "Local directory where the KUBECONFIG file will be written"
  type        = string
}

variable "k3s_version" {
  description = "The K3s version to use"
  type        = string
  default     = "v1.19.2-k3s1"
}
