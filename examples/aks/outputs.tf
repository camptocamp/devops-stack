output "ingress_domain" {
  description = "The domain to use for accessing the applications."
  value       = "${module.aks.cluster_name}.${module.aks.base_domain}"
}

output "cluster_issuers" {
  description = "Map containing the cluster issuers created by cert-manager."
  value       = module.cert-manager.cluster_issuers
}
