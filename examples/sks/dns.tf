# Requires a subscription to Exoscale DNS service, which should be mannually activated on the web console.
# If using nip.io, which is deployed automatically, both these resources are not needed and should be commented 
# or deleted.

resource "exoscale_domain" "domain" {
  name = local.base_domain
}

# This resource should be deactivated if there are multiple development clusters on the same account.
resource "exoscale_domain_record" "wildcard" {
  count = local.activate_wildcard_record ? 1 : 0

  domain      = resource.exoscale_domain.domain.id
  name        = "*.apps"
  record_type = "A"
  ttl         = "300"
  content     = module.sks.nlb_ip_address
}
