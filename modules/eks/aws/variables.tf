variable "cluster_name" {
  type        = string
}

variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
  default     = null
}

variable "kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.21"
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_id" {
  description = "VPC where the cluster and nodes will be deployed."
  type        = string
}

variable "vpc_cidr_block" {
  description = ""
  type        = string
}

variable "private_subnet_ids" {
  description = "List of IDs of private subnets that the EKS instances will be attached to."
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of IDs of public subnets the public NLB will be attached to if enabled with 'create_public_nlb'."
  type        = list(string)
  default     = []
}

variable "aws_auth_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap. See examples/basic/variables.tf in the terraform-aws-eks module's code for example format."
  type        = list(string)
  default     = []
}

variable "aws_auth_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap. See examples/basic/variables.tf in the terraform-aws-eks module's code for example format."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "aws_auth_users" {
  description = "Additional IAM users to add to the aws-auth configmap. See examples/basic/variables.tf in the terraform-aws-eks module's code for example format."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "node_groups" {
  description = "A map of node group configurations to be created."
  type        = any
  default     = {} 
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

variable "nlb_attached_node_groups" {
  description = "List of node_groups indexes that the NLB(s) should be attached to"
  type        = list
  default     = []
}

variable "enable_cluster_autoscaler" {
  description = "Whether to setup a cluster autoscaler"
  type        = bool
  default     = false
}

variable "cluster_autoscaler_role_arn" {
  description = "Role ARN linked to the cluster autoscaler ServiceAccount"
  type        = string
  default     = ""
}

variable "extra_lb_target_groups" {
  description = "Additional load-balancer target groups"
  type        = list(any)
  default     = []
}

variable "extra_lb_http_tcp_listeners" {
  description = "Additional load-balancer listeners"
  type        = list(any)
  default     = []
}
