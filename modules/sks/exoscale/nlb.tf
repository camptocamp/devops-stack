resource "exoscale_nlb" "this" {
  zone = var.zone
  name = format("ingresses-%s", var.cluster_name)
}

resource "exoscale_nlb_service" "http" {
  zone             = exoscale_nlb.this.zone
  name             = "ingress-contoller-http"
  nlb_id           = exoscale_nlb.this.id
  instance_pool_id = module.cluster.nodepools[var.router_nodepool].instance_pool_id
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
  instance_pool_id = module.cluster.nodepools[var.router_nodepool].instance_pool_id
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
