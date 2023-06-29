output "kube_admin_config" {
  value = {
    host                   = ovh_cloud_project_kube.k8s_cluster.kubeconfig_attributes.0.host
    client_key             = ovh_cloud_project_kube.k8s_cluster.kubeconfig_attributes.0.client_key
    cluster_ca_certificate = base64decode(ovh_cloud_project_kube.k8s_cluster.kubeconfig_attributes.0.cluster_ca_certificate)
    client_certificate     = base64decode(ovh_cloud_project_kube.k8s_cluster.kubeconfig_attributes.0.client_certificate)
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
