locals {
  base_domain = coalesce(var.base_domain, format("%s.nip.io", replace(exoscale_nlb.this.ip_address, ".", "-")))
}

module "cluster" {
  source  = "camptocamp/sks/exoscale"
  version = "0.4.1"

  kubernetes_version = var.kubernetes_version
  name               = var.cluster_name
  zone               = var.zone

  nodepools = var.nodepools
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
