locals {
  context = yamldecode(file(format("../terraform/terraform.tfstate.d/%s/kubeconfig.yaml", terraform.workspace)))
  cluster = lookup(lookup(local.context, "clusters")[0], "cluster")
  user    = lookup(lookup(local.context, "users")[0], "user")
}

provider "kubernetes" {
  host                   = lookup(local.cluster, "server")
  client_certificate     = base64decode(lookup(local.user, "client-certificate-data"))
  client_key             = base64decode(lookup(local.user, "client-key-data"))
  cluster_ca_certificate = base64decode(lookup(local.cluster, "certificate-authority-data"))
}

data "kubernetes_pod" "vault_0" {
  metadata {
    name      = "vault-0"
    namespace = "vault"
  }
}

provider "vault" {
  token           = "root"
  skip_tls_verify = true
}

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
}

resource "vault_kubernetes_auth_backend_config" "in_cluster" {
  backend            = vault_auth_backend.kubernetes.path
  kubernetes_host    = lookup(local.cluster, "server")
  kubernetes_ca_cert = base64decode(lookup(local.cluster, "certificate-authority-data"))
}
