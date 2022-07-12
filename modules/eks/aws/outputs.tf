output "cluster_name" {
  value = var.cluster_name
}

output "base_domain" {
  value = local.base_domain
}

output "cluster_id" {
  description = "The name/id of the EKS cluster. Will block on cluster creation until the cluster is really ready"
  value       = module.cluster.cluster_id
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster OIDC Issuer"
  value       = module.cluster.cluster_oidc_issuer_url
}

output "node_security_group_id" {
  value = module.cluster.node_security_group_id
}

output "node_groups" {
  description = "Security group ID attached to the EKS nodes."
  value       = module.cluster.self_managed_node_groups
}

output "kubernetes_host" {
  value = module.cluster.cluster_endpoint
}

output "kubernetes_cluster_ca_certificate" {
  value = base64decode(module.cluster.cluster_certificate_authority_data)
}

output "kubernetes_token" {
  value = data.aws_eks_cluster_auth.cluster.token
}

output "nlb_target_groups" {
  value = concat(module.nlb.target_group_arns, module.nlb_private.target_group_arns)
}

output "kubernetes" {
  value = {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)
  }
}
