module "ebs_csi_driver_blue" {
  source = "git::https://github.com/camptocamp/devops-stack-module-ebs-csi-driver.git?ref=v2.0.1"

  cluster_name     = module.eks.cluster_name
  argocd_namespace = "argocd"

  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  create_role = true
}

