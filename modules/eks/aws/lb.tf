locals {
  nlb_name_prefix = substr(var.cluster_name, 0, 5)
}

module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "5.10.0"

  create_lb = var.create_public_nlb

  name = var.cluster_name

  load_balancer_type = "network"

  vpc_id                           = data.aws_vpc.this.id
  subnets                          = data.aws_subnet_ids.public.ids
  enable_cross_zone_load_balancing = true

  target_groups = [
    {
      name_prefix      = local.nlb_name_prefix
      backend_protocol = "TCP"
      backend_port     = 443
      target_type      = "instance"
    },
    {
      name_prefix      = local.nlb_name_prefix
      backend_protocol = "TCP"
      backend_port     = 80
      target_type      = "instance"
    },
  ]

  http_tcp_listeners = [
    {
      port               = 443
      protocol           = "TCP"
      target_group_index = 0
    },
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    },
  ]
}

module "nlb_private" {
  source  = "terraform-aws-modules/alb/aws"
  version = "5.10.0"

  create_lb = var.create_private_nlb

  name = "${var.cluster_name}-private"

  load_balancer_type = "network"

  vpc_id                           = data.aws_vpc.this.id
  subnets                          = data.aws_subnet_ids.private.ids
  enable_cross_zone_load_balancing = true
  internal                         = true

  target_groups = [
    {
      name_prefix      = local.nlb_name_prefix
      backend_protocol = "TCP"
      backend_port     = 443
      target_type      = "instance"
    },
    {
      name_prefix      = local.nlb_name_prefix
      backend_protocol = "TCP"
      backend_port     = 80
      target_type      = "instance"
    },
  ]

  http_tcp_listeners = [
    {
      port               = 443
      protocol           = "TCP"
      target_group_index = 0
    },
    {
      port               = 80
      protocol           = "TCP"
      target_group_index = 0
    },
  ]
}

resource "aws_route53_record" "wildcard" {
  count = var.create_public_nlb || var.create_private_nlb ? 1 : 0

  zone_id = data.aws_route53_zone.this.id
  name    = format("*.apps.%s", var.cluster_name)
  type    = "CNAME"
  ttl     = "300"
  records = [
    var.create_public_nlb ? module.nlb.this_lb_dns_name : module.nlb_private.this_lb_dns_name,
  ]
}
