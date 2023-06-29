output "kube_admin_config" {
  value = {
    context                           = local.context
    kubernetes_host                   = local.kubernetes_host
    kubernetes_cluster_ca_certificate = local.kubernetes_cluster_ca_certificate
    kubernetes_client_certificate     = local.kubernetes_client_certificate
    kubernetes_client_key             = local.kubernetes_client_key
  }
}

output "kubeconfig_file" {
  value     = ovh_cloud_project_kube.k8s_cluster.kubeconfig
  sensitive = true
}

output "kubeconfig" {
  value     = ovh_cloud_project_kube.k8s_cluster.kubeconfig
  sensitive = true
}

output "openstackID" {
  value = one(ovh_cloud_project_network_private.network.regions_attributes[*].openstackid)
}
