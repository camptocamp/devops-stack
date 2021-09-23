output "ingress_lb_loadbalancer_v2_vip_address" {
  value = opentelekomcloud_lb_loadbalancer_v2.ingress.vip_address
}

output "keycloak_users" {
  value     = { for username, infos in local.keycloak_user_map : username => lookup(infos, "password") }
  sensitive = true
}
