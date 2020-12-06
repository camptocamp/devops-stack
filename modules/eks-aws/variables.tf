variable "cluster_name" {
  description = "The name of the cluster to create."
  type        = string
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_id" {
  description = "VPC where the cluster and workers will be deployed."
  type        = string
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap. See examples/basic/variables.tf for example format."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "worker_groups" {
  description = "A list of maps defining worker group configurations to be defined using AWS Launch Configurations. See workers_group_defaults for valid keys."
  type        = any
  default     = []
}

variable "base_domain" {
  description = "The base domain used for Ingresses."
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

variable "cognito_user_pool_id" {
  description = "ID of the Cognito user pool to use."
  type        = string
}

variable "cognito_user_pool_domain" {
  description = "Domain prefix of the Cognito user pool to use (custom domain currently not supported!)."
  type        = string
}

variable "app_of_apps_values_overrides" {
  description = "App of apps values overrides."
  type        = string
  default     = ""
}

variable "extra_apps" {
  description = "Extra applications to deploy."
  type        = list
  default     = []
}

variable "kubeconfig_aws_authenticator_command" {
  description = "Override the kubeconfig authenticator command"
  type        = string
  default     = "aws-iam-authenticator"
}

variable "kubeconfig_aws_authenticator_command_args" {
  description = "Override the kubeconfig authenticator arguments"
  type        = list(string)
  default     = []
}

variable "enable_efs" {
  description = "Whether to provision an EFS filesystem, along with a provisioner"
  type        = bool
  default     = false
}

variable "create_public_nlb" {
  description = "Whether to create an internet-facing NLB attached to the public subnets"
  type        = bool
  default     = true
}

variable "create_private_nlb" {
  description = "Whether to create an internal NLB attached the private subnets"
  type        = bool
  default     = false
}

variable "enable_metrics_archives" {
  description = "Whether to enable prometheus to flush WAL to object storage"
  type        = bool
  default     = false
}

variable "thanos_archives_endpoint" {
  description = "S3 like endpoint for thanos long term storage"
  type        = string
  default     = ""
}

variable "thanos_archives_bucket_name" {
  description = "Bucket name for thanos"
  type        = string
  default     = "thanos"
}
