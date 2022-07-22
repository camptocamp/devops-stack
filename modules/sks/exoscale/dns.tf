data "exoscale_domain" "this" {
  count = var.base_domain == null ? 0 : 1
  name  = var.base_domain
}

resource "exoscale_domain_record" "wildcard" {
  count = var.base_domain != null ? 1 : 0

  domain      = data.exoscale_domain.this.0.id
  name        = format("*.apps.%s", var.cluster_name)
  record_type = "A"
  ttl         = "300"
  prio        = 1 # because bug in exoscale provider 0.39.0
  content     = exoscale_nlb.this.ip_address
}
