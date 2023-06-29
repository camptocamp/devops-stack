output "kube_admin_config" {
  value = {
    host                   = ovh_cloud_project_kube.k8s_cluster.kubeconfig.0.host
    token                  = ovh_cloud_project_kube.k8s_cluster.kubeconfig.0.token
    cluster_ca_certificate = base64decode(ovh_cloud_project_kube.k8s_cluster.kubeconfig.0.cluster_ca_certificate)
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
