locals {
  grafana_admin_password = var.grafana_admin_password == null ? random_password.grafana_admin_password.0.result : var.grafana_admin_password
}

resource "random_password" "grafana_admin_password" {
  count = var.grafana_admin_password == null ? 1 : 0

  length  = 16
  special = false
}
