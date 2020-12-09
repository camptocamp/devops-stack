variable "repo_url" {
  description = "The source repo URL of ArgoCD's app of apps."
  type        = string
}

variable "target_revision" {
  description = "The source target revision of ArgoCD's app of apps."
  type        = string
}

variable "extra_apps" {
  description = "Extra applications to deploy."
  type        = list(any)
  default     = []
}

variable "cluster_name" {
  description = "The name of the cluster to create."
  type        = string
}

variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
}

variable "cluster_issuer" {
  description = "Cluster Issuer"
  type        = string
}

variable "oidc" {
  description = "OIDC Settings"
  type        = any
  default     = {}
}

variable "argocd" {
  description = "ArgoCD settings"
  type        = any
  default     = {}
}

variable "grafana" {
  description = "Grafana settings"
  type        = any
  default     = {}
}

variable "prometheus" {
  description = "Prometheus settings"
  type        = any
  default     = {}
}

variable "alertmanager" {
  description = "Alertmanager settings"
  type        = any
  default     = {}
}

variable "loki" {
  description = "Loki settings"
  type        = any
  default     = {}
}

variable "efs_provisioner" {
  description = "EFS provisioner settings"
  type        = any
  default     = {}
}

variable "keycloak" {
  description = "Keycloak settings"
  type        = any
  default     = {}
}

variable "olm" {
  description = "OLM settings"
  type        = any
  default     = {}
}

variable "minio" {
  description = "Minio settings"
  type        = any
  default     = {}
}

variable "app_of_apps_values_overrides" {
  description = "Extra value files content for the App of Apps"
  type        = list(string)
  default     = []
}
