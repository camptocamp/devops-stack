variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.21"
}

variable "base_domain" {
  description = "The base domain used for Ingresses."
  type        = string
  default     = null
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "vpc_id" {
  description = "VPC where the cluster and nodes/workers will be deployed."
  type        = string
}

variable "map_accounts" {
  description = "Additional AWS account numbers to add to the aws-auth configmap. See examples/basic/variables.tf in the terraform-aws-eks module's code for example format."
  type        = list(string)
  default     = []
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap. See examples/basic/variables.tf in the terraform-aws-eks module's code for example format."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap. See examples/basic/variables.tf in the terraform-aws-eks module's code for example format."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []
}

variable "cognito_user_pool_id" {
  description = "ID of the Cognito user pool to use."
  type        = string
}

variable "cognito_user_pool_domain" {
  description = "Domain prefix of the Cognito user pool to use (custom domain currently not supported!)."
  type        = string
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

variable "enable_cluster_autoscaler" {
  description = "Whether to setup a cluster autoscaler"
  type        = bool
  default     = false
}

variable "node_pools" {
  description = <<-EOF
    A list of nodes pools to be provisioned for the cluster.
    Each node_pool should include at least a `name` key.
    Entry node_pools.0, if defined, acts as ingress node pool, else a default one will be created.
    See provider `terraform-aws-modules/eks/aws` workers_group_defaults for valid keys.

    Example:

    ```
    node_pools = [
      {
        name = infra
      },
      {
        name = prod
      },
      {
        name = int
      }
    ]
    ```
  EOF
  type = list(any)
  default = []
}
