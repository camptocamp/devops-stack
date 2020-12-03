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
  type        = list
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

variable "oidc_issuer_url" {
  description = "OIDC Issuer URL"
  type        = string
  default     = ""
}

variable "oauth2_oauth_url" {
  description = "OAuth2 OAuth URL"
  type        = string
  default     = ""
}

variable "oauth2_token_url" {
  description = "OAuth2 Token URL"
  type        = string
  default     = ""
}

variable "oauth2_api_url" {
  description = "OAuth2 API URL"
  type        = string
  default     = ""
}

variable "oauth2_proxy_extra_args" {
  description = "Extra arguments to pass to the OAuth2 proxy"
  type        = list(string)
  default     = []
}

variable "client_id" {
  description = "Authentication Client ID"
  type        = string
}

variable "client_secret" {
  description = "Authentication Client Secret"
  type        = string
}

variable "grafana_generic_oauth_extra_args" {
  description = "Generic OAuth extra args for Grafana"
  type        = map
  default     = {}
}

variable "loki_bucket_name" {
  description = "Name of the Loki bucket"
  type        = string
}

variable "enable_efs" {
  description = "Whether to activate the EFS provisioner"
  type        = bool
  default     = false
}

variable "enable_keycloak" {
  description = "Whether to activate Keycloak"
  type        = bool
  default     = true
}

variable "admin_password" {
  description = "Keycloak Admin Password"
  type        = string
  default     = ""
}

variable "enable_olm" {
  description = "Whether to activate OLM"
  type        = bool
  default     = false
}

variable "enable_minio" {
  description = "Whether to activate Minio"
  type        = bool
  default     = false
}

variable "minio_access_key" {
  description = "Minio Access Key"
  type        = string
  default     = ""
}

variable "minio_secret_key" {
  description = "Minio Secret Key"
  type        = string
  default     = ""
}

variable "app_of_apps_values_overrides" {
  description = "Extra value files content for the App of Apps"
  type        = list(string)
}
