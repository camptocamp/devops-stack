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
  count = 3

  file_system_id  = aws_efs_file_system.eks.id
  subnet_id       = element(module.vpc.private_subnets, count.index)
  security_groups = [aws_security_group.efs_eks.id]
}


module "efs" {
  source = "git::https://github.com/camptocamp/devops-stack-module-efs-csi-driver.git"

  argocd_namespace   = local.argocd_namespace
  efs_file_system_id = aws_efs_file_system.eks.id

  depends_on = [module.argocd_bootstrap]
}

