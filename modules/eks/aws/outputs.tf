output "base_domain" {
  value = local.base_domain
}

output "oidc" {
  value = local.oidc
}

output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.cluster.cluster_id
}

output "cluster_issuer" {
  value = local.cluster_issuer
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.cluster.cluster_oidc_issuer_url
}

output "worker_security_group_id" {
  description = "Security group ID attached to the EKS workers."
  value       = module.cluster.worker_security_group_id
}

output "worker_iam_role_name" {
  description = "default IAM role name for EKS worker groups"
  value       = module.cluster.worker_iam_role_name
}

output "kubernetes_host" {
  value = local.kubernetes_host
}

output "kubernetes_cluster_ca_certificate" {
  value = local.kubernetes_cluster_ca_certificate
}

output "kubernetes_token" {
  value = local.kubernetes_token
}
