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

variable "oidc" {
  description = "OIDC Settings"
  type        = object({
    issuer_url              = string
    oauth_url               = string
    token_url               = string
    api_url                 = string
    oauth2_proxy_extra_args = list(string)
    client_id               = string
    client_secret           = string
  })
  default     = {
    issuer_url              = ""
    oauth_url               = ""
    token_url               = ""
    api_url                 = ""
    client_id               = ""
    client_secret           = ""
    oauth2_proxy_extra_args = []
  }
}

variable "grafana" {
  description = "Grafana settings"
  type        = object({
    generic_oauth_extra_args = map(any)
  })
  default     = {
    generic_oauth_extra_args = {}
  }
}

variable "loki" {
  description = "Loki settings"
  type = object({
    bucket_name = string
  })
  default = {
    bucket_name = ""
  } 
}

variable "efs_provisioner" {
  description = "EFS provisioner settings"
  type        = object({
    enable = bool
  })
  default     = {
    enable = false
  } 
}

variable "keycloak" {
  description = "Keycloak settings"
  type        = object({
    enable         = bool
    admin_password = string
  })
  default     = {
    enable         = false
    admin_password = ""
  } 
}

variable "olm" {
  description = "OLM settings"
  type        = object({
    enable = bool
  })
  default     = {
    enable = false
  }
}

variable "minio" {
  description = "Minio settings"
  type        = object({
    enable     = bool
    access_key = string
    secret_key = string
  })
  default = {
    enable     = false
    access_key = ""
    secret_key = ""
  }
}

variable "app_of_apps_values_overrides" {
  description = "Extra value files content for the App of Apps"
  type        = list(string)
  default     = []
}
