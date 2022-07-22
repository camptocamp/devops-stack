locals {
  base_domain = coalesce(var.base_domain, format("%s.nip.io", replace(data.dns_a_record_set.nlb.addrs[0], ".", "-")))
}

data "aws_region" "current" {}

data "aws_route53_zone" "this" {
  count = var.base_domain == null ? 0 : 1

  name = var.base_domain
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.cluster.cluster_id
}

locals {
#  target_group_arns = concat(module.nlb.target_group_arns, module.nlb_private.target_group_arns)
#  target_groups_node_groups = { for group in var.nlb_attached_node_groups : group => { target_group_arns = local.target_group_arns } }
}


module "cluster" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~>18.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  subnet_ids       = var.private_subnet_ids
  vpc_id           = var.vpc_id
  enable_irsa      = true

  create_aws_auth_configmap = true
  manage_aws_auth_configmap = true

  aws_auth_accounts = var.aws_auth_accounts
  aws_auth_roles    = var.aws_auth_roles
  aws_auth_users    = var.aws_auth_users

  self_managed_node_groups = var.node_groups

  self_managed_node_group_defaults = {
    create_security_group = false
  }

  cluster_security_group_additional_rules = {
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    ingress_all_http = {
      description      = "Node http ingress"
      protocol         = "tcp"
      from_port        = 80
      to_port          = 80
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_all_https = {
      description      = "Node https ingress"
      protocol         = "tcp"
      from_port        = 443
      to_port          = 443
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_cluster_to_nodes_metrics_server = {
      description      = "Cluster to node Metrics Server"
      protocol         = "tcp"
      from_port        = 4443
      to_port          = 4443
      type             = "ingress"
      source_cluster_security_group = true 
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }
}

#resource "aws_security_group_rule" "workers_ingress_healthcheck_https" {
#  security_group_id = module.cluster.node_security_group_id
#  type              = "ingress"
#  protocol          = "TCP"
#  from_port         = 443
#  to_port           = 443
#  cidr_blocks       = [var.vpc_cidr_block]
#}
#resource "aws_security_group_rule" "workers_ingress_healthcheck_http" {
#  security_group_id = module.cluster.node_security_group_id
#  type              = "ingress"
#  protocol          = "TCP"
#  from_port         = 80
#  to_port           = 80
#  cidr_blocks       = [var.vpc_cidr_block]
#}
