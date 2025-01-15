data "aws_availability_zones" "available" {}

module "vpc" {
  source               = "terraform-aws-modules/vpc/aws"
  version              = "~> 5.0"
  name                 = module.eks.cluster_name
  cidr                 = local.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = local.private_subnets
  public_subnets       = local.public_subnets
  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true

  private_subnet_tags = {
    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"                  = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${module.eks.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                           = "1"
  }
}

module "eks" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cluster-eks.git?ref=v4.2.0"

  cluster_name       = local.cluster_name
  kubernetes_version = local.kubernetes_version
  base_domain        = local.base_domain
  subdomain          = local.subdomain

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  public_subnet_ids  = module.vpc.public_subnets

  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  node_groups = {
    "${module.eks.cluster_name}-main" = {
      ami_type        = "AL2_ARM_64" # Use 'AL2_x86_64' for x86 VMs like 'm5.large'
      instance_types  = ["m7g.xlarge"]
      min_size        = 3
      max_size        = 3
      desired_size    = 3
      nlbs_attachment = true
      disk_size       = 50
      labels = {
        "devops-stack.io/nodepool" = "main"
      }
    },
  }

  create_public_nlb = true
}

module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-oidc-aws-cognito.git?ref=v1.1.1"

  cluster_name = module.eks.cluster_name
  base_domain  = module.eks.base_domain
  subdomain    = local.subdomain

  create_pool = true

  user_map = {
    YOUR_USERNAME = {
      username   = "YOUR_USERNAME"
      email      = "YOUR_EMAIL"
      first_name = "YOUR_FIRST_NAME"
      last_name  = "YOUR_LAST_NAME"
    }
  }
}

module "argocd_bootstrap" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git//bootstrap?ref=v7.2.0"

  argocd_projects = {
    "${module.eks.cluster_name}" = {
      destination_cluster = "in-cluster"
    }
  }

  depends_on = [module.eks]
}

module "metrics-server" {
  source = "git::https://github.com/camptocamp/devops-stack-module-metrics-server.git?ref=v3.0.0"

  argocd_project = module.eks.cluster_name

  app_autosync = local.app_autosync

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "traefik" {
  source = "git::https://github.com/camptocamp/devops-stack-module-traefik.git//eks?ref=v9.0.2"

  argocd_project = module.eks.cluster_name

  app_autosync           = local.app_autosync
  enable_service_monitor = local.enable_service_monitor

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "cert-manager" {
  source = "git::https://github.com/camptocamp/devops-stack-module-cert-manager.git//eks?ref=v10.0.0"

  cluster_name   = module.eks.cluster_name
  base_domain    = module.eks.base_domain
  argocd_project = module.eks.cluster_name

  letsencrypt_issuer_email = local.letsencrypt_issuer_email

  app_autosync           = local.app_autosync
  enable_service_monitor = local.enable_service_monitor

  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
  }
}

module "loki-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-loki-stack.git//eks?ref=v11.0.0"

  argocd_project = module.eks.cluster_name

  app_autosync = local.app_autosync

  logs_storage = {
    bucket_id               = aws_s3_bucket.loki_logs_storage.id
    create_role             = true
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  }

  dependency_ids = {
    argocd = module.argocd_bootstrap.id
    ebs    = module.ebs.id
  }
}

module "thanos" {
  source = "git::https://github.com/camptocamp/devops-stack-module-thanos.git//eks?ref=v7.0.1"

  cluster_name   = module.eks.cluster_name
  base_domain    = module.eks.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer
  argocd_project = module.eks.cluster_name

  app_autosync           = local.app_autosync
  enable_service_monitor = local.enable_service_monitor

  metrics_storage = {
    bucket_id               = aws_s3_bucket.thanos_metrics_storage.id
    create_role             = true
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  }

  thanos = {
    oidc = module.oidc.oidc
  }

  dependency_ids = {
    argocd       = module.argocd_bootstrap.id
    ebs          = module.ebs.id
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    oidc         = module.oidc.id
  }
}

module "kube-prometheus-stack" {
  source = "git::https://github.com/camptocamp/devops-stack-module-kube-prometheus-stack.git//eks?ref=v13.0.1"

  cluster_name   = module.eks.cluster_name
  base_domain    = module.eks.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer
  argocd_project = module.eks.cluster_name

  app_autosync = local.app_autosync

  metrics_storage = {
    bucket_id               = aws_s3_bucket.thanos_metrics_storage.id
    create_role             = true
    cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  }

  prometheus = {
    oidc = module.oidc.oidc
  }

  alertmanager = {
    oidc = module.oidc.oidc
  }

  grafana = {
    oidc = module.oidc.oidc
  }

  dependency_ids = {
    argocd       = module.argocd_bootstrap.id
    ebs          = module.ebs.id
    traefik      = module.traefik.id
    cert-manager = module.cert-manager.id
    oidc         = module.oidc.id
    thanos       = module.thanos.id
    loki-stack   = module.loki-stack.id
  }
}

module "argocd" {
  source = "git::https://github.com/camptocamp/devops-stack-module-argocd.git?ref=v7.2.0"

  cluster_name   = module.eks.cluster_name
  base_domain    = module.eks.base_domain
  subdomain      = local.subdomain
  cluster_issuer = local.cluster_issuer
  argocd_project = module.eks.cluster_name

  accounts_pipeline_tokens = module.argocd_bootstrap.argocd_accounts_pipeline_tokens
  server_secretkey         = module.argocd_bootstrap.argocd_server_secretkey

  app_autosync = local.app_autosync

  admin_enabled = false
  exec_enabled  = true

  oidc = {
    name         = "Cognito"
    issuer       = module.oidc.oidc.issuer_url
    clientID     = module.oidc.oidc.client_id
    clientSecret = module.oidc.oidc.client_secret
    requestedIDTokenClaims = {
      groups = {
        essential = true
      }
    }
    requestedScopes = [
      "openid", "profile", "email"
    ]
  }

  rbac = {
    policy_csv = <<-EOT
      g, pipeline, role:admin
      g, devops-stack-admins, role:admin
    EOT
  }

  dependency_ids = {
    argocd                = module.argocd_bootstrap.id
    traefik               = module.traefik.id
    cert-manager          = module.cert-manager.id
    oidc                  = module.oidc.id
    kube-prometheus-stack = module.kube-prometheus-stack.id
  }
}
