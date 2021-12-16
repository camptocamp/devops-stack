variable "kubeconfig" {
  description = "The content of the KUBECONFIG file."
  type        = string
}

variable "repo_url" {
  description = "The source repo URL of ArgoCD's app of apps."
  type        = string
}

variable "target_revision" {
  description = "The source target revision of ArgoCD's app of apps."
  type        = string
}

variable "extra_apps" {
  description = "Extra Applications objects to deploy."
  type        = list(any)
  default     = []
}

variable "extra_app_projects" {
  description = "Extra AppProjects objects to deploy."
  type        = list(any)
  default     = []
}

variable "extra_application_sets" {
  description = "Extra ApplicationSets objects to deploy."
  type        = list(any)
  default     = []
}

variable "argocd_server_secretkey" {
  description = "ArgoCD Server Secert Key to avoid regenerate token on redeploy."
  type        = string
  default     = null
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


variable "loki" {
  description = "Loki settings"
  type        = any
  default     = {}
}

variable "traefik" {
  description = "Trafik settings"
  type        = any
  default     = {}
}

variable "keycloak" {
  description = "Keycloak settings"
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

variable "metrics_server" {
  description = "Metrics server settings"
  type        = any
  default     = {}
}

variable "metrics_archives" {
  description = "Metrics archives settings"
  type        = any
  default     = {}
}

variable "cert_manager" {
  description = "Cert Manager settings"
  type        = any
  default     = {}
}

variable "kube_prometheus_stack" {
  description = "Kube-prometheus-stack settings"
  type        = any
  default     = {}
}

variable "cluster_autoscaler" {
  description = "Cluster Autoscaler settings"
  type        = any
  default     = {}
}

variable "wait_for_app_of_apps" {
  description = "Allow to disable wait for app of apps"
  type        = bool
  default     = true
}

variable "repositories" {
  description = "A list of repositories to add to ArgoCD."
  type        = map(map(string))
  default     = {}
}
