variable "cluster_name" {
  description = "The name of the Kubernetes cluster to create."
  type        = string
}

variable "base_domain" {
  description = "The base domain of the Kubernetes cluster to create."
  type        = string
}

variable "cluster_region" {
  description = "The region from which we want to create the cluster"
  type        = string
}

variable "flavor_name" {
  description = "The type of instance for the nodepool"
  type        = string
}

variable "desired_nodes" {
  description = "The number of node we want"
  type        = number
}

variable "max_nodes" {
  description = "The number of node we want at maximum"
  type        = number
}

variable "min_nodes" {
  description = "The number of node we want at minimum"
  type        = number
}

variable "vlan_name" {
  description = "The Name of the virtual network"
  type        = string
}

variable "vlan_subnet_start" {
  description = "IP address to begin with for this subnet ex : 192.168.168.100"
  type        = string
}

variable "vlan_subnet_end" {
  description = "IP address to end with for this subnet ex : 192.168.168.200"
  type        = string
}

variable "vlan_subnet_network" {
  description = "IP address scope for this network 192.168.168.0/24"
  type        = string
}
