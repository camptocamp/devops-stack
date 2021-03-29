locals {
  grafana_admin_password = var.grafana_admin_password == null ? random_password.grafana_admin_password.result : var.grafana_admin_password
}

resource "random_password" "grafana_admin_password" {
  length  = 16
  special = false
}
