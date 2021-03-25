output "console_url" {
  value = "https://console-openshift-console.apps.${var.cluster_name}.${var.base_domain}"
}

output "kubeadmin_password" {
  value     = module.cluster.kubeadmin_password
  sensitive = true
}
