output "kubeconfig_file" {
  sensitive = true
  value     = module.scaleway.kubeconfig_file
}

output "base_domain" {
  value = module.scaleway.base_domain
}

