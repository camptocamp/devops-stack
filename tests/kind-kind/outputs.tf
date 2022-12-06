output "cluster_name" {
  description = "The name to given to the cluster."
  value       = module.kind.cluster_name
}

output "base_domain" {
  description = "The base domain used for ingresses."
  value       = module.kind.base_domain
}

output "kubernetes_kubeconfig" {
  description = "Configuration that can be copied into `.kube/config in order to access the cluster with `kubectl`."
  value       = module.kind.kubernetes_kubeconfig
}
