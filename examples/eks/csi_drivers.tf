resource "aws_efs_file_system" "eks" {
  creation_token = module.eks.cluster_name

  tags = {
    Name = module.eks.cluster_name
  }
}

resource "aws_security_group" "efs_eks" {
  name        = "efs-devops-stack"
  description = "Security group for EFS"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }
}

resource "aws_efs_mount_target" "eks" {
  count = length(local.private_subnets)

  file_system_id  = resource.aws_efs_file_system.eks.id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [resource.aws_security_group.efs_eks.id]
}

module "efs" {
  source = "git::https://github.com/camptocamp/devops-stack-module-efs-csi-driver.git?ref=v2.2.0"

  cluster_name     = local.cluster_name
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  app_autosync     = local.app_autosync

  efs_file_system_id      = resource.aws_efs_file_system.eks.id
  create_role             = true
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "ebs" {
  source = "git::https://github.com/camptocamp/devops-stack-module-ebs-csi-driver.git?ref=v2.3.0"

  cluster_name     = local.cluster_name
  argocd_namespace = module.argocd_bootstrap.argocd_namespace
  app_autosync     = local.app_autosync

  create_role             = true
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}
