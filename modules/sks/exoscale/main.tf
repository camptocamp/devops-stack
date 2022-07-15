locals {
  base_domain = coalesce(var.base_domain, format("%s.nip.io", replace(exoscale_nlb.this.ip_address, ".", "-")))

  default_nodepools = {
    "router-${var.cluster_name}" = {
      size          = 2
      instance_type = "standard.large"
    },
  }

  router_nodepool = coalesce(var.router_nodepool, "router-${var.cluster_name}")
  router_pool_id  = module.cluster.nodepools[local.router_nodepool].instance_pool_id
  nodepools       = coalesce(var.nodepools, local.default_nodepools)
  cluster_issuer  = (length(local.nodepools) > 1) ? "letsencrypt-prod" : "ca-issuer"
}

module "cluster" {
  source  = "camptocamp/sks/exoscale"
  version = "0.3.0"

  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  zone               = var.zone

  nodepools = local.nodepools
}

resource "exoscale_nlb" "this" {
  zone = var.zone
  name = format("ingresses-%s", var.cluster_name)
}

resource "exoscale_nlb_service" "http" {
  zone             = exoscale_nlb.this.zone
  name             = "ingress-contoller-http"
  nlb_id           = exoscale_nlb.this.id
  instance_pool_id = module.cluster.nodepools[local.router_nodepool].instance_pool_id
  protocol         = "tcp"
  port             = 80
  target_port      = 80
  strategy         = "round-robin"

  healthcheck {
    mode     = "tcp"
    port     = 80
    interval = 5
    timeout  = 3
    retries  = 1
  }
}

resource "exoscale_nlb_service" "https" {
  zone             = exoscale_nlb.this.zone
  name             = "ingress-contoller-https"
  nlb_id           = exoscale_nlb.this.id
  instance_pool_id = module.cluster.nodepools[local.router_nodepool].instance_pool_id
  protocol         = "tcp"
  port             = 443
  target_port      = 443
  strategy         = "round-robin"

  healthcheck {
    mode     = "tcp"
    port     = 443
    interval = 5
    timeout  = 3
    retries  = 1
  }
}

resource "exoscale_security_group_rule" "http" {
  security_group_id = module.cluster.this_security_group_id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 80
  end_port          = 80
}

resource "exoscale_security_group_rule" "https" {
  security_group_id = module.cluster.this_security_group_id
  type              = "INGRESS"
  protocol          = "TCP"
  cidr              = "0.0.0.0/0"
  start_port        = 443
  end_port          = 443
}

resource "exoscale_security_group_rule" "all" {
  security_group_id      = module.cluster.this_security_group_id
  user_security_group_id = module.cluster.this_security_group_id
  type                   = "INGRESS"
  protocol               = "TCP"
  start_port             = 1
  end_port               = 65535
}
