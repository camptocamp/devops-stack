output "base_domain" {
  value = local.base_domain
}

output "kubernetes_host" {
  value = local.kubernetes_host
}

output "kubernetes_username" {
  value = local.kubernetes_username
}

output "kubernetes_password" {
  value = local.kubernetes_password
}

output "kubernetes_cluster_ca_certificate" {
  value = local.kubernetes_cluster_ca_certificate
}

output "kubeconfig" {
  value = module.cluster.kubeconfig
}

output "admin_password" {
  value = random_password.admin_password.result
}
