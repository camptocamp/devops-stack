data "exoscale_domain" "this" {
  name = module.sks.base_domain
}

resource "exoscale_domain_record" "wildcard" {
  domain      = data.exoscale_domain.this.id
  name        = "*.apps"
  record_type = "CNAME"
  ttl         = "300"
  prio        = 1 # because bug in exoscale provider 0.39.0
  content     = format("default.apps.%s.%s", module.sks.cluster_name, module.sks.base_domain)
}
