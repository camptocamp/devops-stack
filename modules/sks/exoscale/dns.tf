data "exoscale_domain" "this" {
  name = local.base_domain
}

resource "exoscale_domain_record" "wildcard" {
  domain      = data.exoscale_domain.this.name
  name        = format("*.apps.%s", var.cluster_name)
  record_type = "A"
  ttl         = 300
  content     = exoscale_nlb.this.ip_address
}
