variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Specify which Kubernetes release to use."
  type        = string
}

variable "cluster_type" {
  description = "The cluster type (\"kapsule\" or \"kosmos\")."
  type        = string
}

variable "zone" {
  description = "The name of the availability zone to deploy the Kubernetes cluster into."
  type        = string
}

variable "region" {
  description = "The name of the region to deploy the Kubernetes cluster into."
  type        = string
}

variable "lb_type" {
  description = "The type of LB to deploy."
  type        = string
}

variable "nodepools" {
  description = "The node pools to create."
  type        = any
  default     = null
}
