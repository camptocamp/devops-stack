provider "vault" {
  token           = "root"
  skip_tls_verify = true
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "in_cluster" {
  backend         = vault_auth_backend.kubernetes.path
  kubernetes_host = "https://kubernetes.default.svc"

  lifecycle {
    ignore_changes = [
      kubernetes_ca_cert,
    ]
  }
}
