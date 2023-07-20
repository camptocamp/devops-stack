# #######################################################
# Proxy input for the particuleio/kapsule/scaleway module
# #######################################################

variable "cluster_name" {
  type        = string
  description = "The name for the Kubernetes cluster"
}

variable "cluster_description" {
  type        = string
  description = "A description for the Kubernetes cluster"
  default     = null
}

variable "cluster_tags" {
  type        = list(any)
  default     = []
  description = "The tags associated with the Kubernetes cluster"
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Tags applied to all ressources."
}

variable "kubernetes_version" {
  default     = "1.24.5"
  type        = string
  description = "The version of the Kubernetes cluster"
}

variable "admission_plugins" {
  type        = list(string)
  default     = []
  description = "The list of admission plugins to enable on the cluster"
}

# ###############################################
# Variable for additional resources/configuration 
# ###############################################
variable "base_domain" {
  description = "A DNS zone if any"
  default     = null
  type        = string
}

variable "lb_type" {
  description = "The type of LB to deploy."
  type        = string
}

variable "lb_name" {
  description = "Name of the load balancer"
  type        = string
}

variable "zone" {
  description = "Zone in the region"
  type        = string
}

variable "node_pools" {
  description = "The node pools to create."
  type        = any
  default     = null
}
#
# ###############################################
# Variable for Ingress configuration 
# ###############################################
variable "ingress_enable_service_monitor" {
  description = "Enable Prometheus ServiceMonitor in the Helm chart."
  type        = bool
}

# ###############################################
# Variable for keycloak configuration 
# ###############################################
variable "cluster_issuer" {
  description = "Cluster issuer"
  type        = string
}

# ###############################################
# Variable for Cert-manager configuration 
# ###############################################
variable "cert_manager_enable_service_monitor" {
  description = "Argocd prometheus conf"
  default     = false
  type        = bool
}
