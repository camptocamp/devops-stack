locals {
  nlb_name_prefix = substr(var.cluster_name, 0, 5)
}

module "nlb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "5.9.0"

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

resource "aws_route53_record" "wildcard" {
  zone_id = data.aws_route53_zone.this.id
  name    = format("*.apps.%s", var.cluster_name)
  type    = "CNAME"
  ttl     = "300"
  records = [
    module.nlb.this_lb_dns_name,
  ]
}

resource "aws_route53_record" "wildcard-short" {
  zone_id = data.aws_route53_zone.this.id
  name    = "*.apps"
  type    = "CNAME"
  ttl     = "300"
  records = [
    module.nlb.this_lb_dns_name,
  ]
}
