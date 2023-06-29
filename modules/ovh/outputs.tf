output "kube_admin_config" {
  value = {
    context                           = yamldecode(module.ovh_k8s.kubeconfig)
    kubernetes_host                   = local.context.clusters.0.cluster.server
    kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
    kubernetes_client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
    kubernetes_client_key             = base64decode(local.context.users.0.user.client-key-data)
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
