locals {

  cluster_name           = var.ENV_FOR_DOMAIN
  cluster_prefix         = var.CLUSTER_PREFIX
  base_domain            = format("%s.%s", local.env, "company.com")
  cluster_datacenter     = var.DATACENTER
  cluster_flavor_name    = var.NODE_POOL
  cluster_desired_nodes  = var.NODE_POOL_DESIRED_NODES
  cluster_max_nodes      = var.NODE_POOL_MAX_NODES
  cluster_min_nodes      = var.NODE_POOL_MIN_NODES
  cluster_issuer         = "letsencrypt-stagging"
  enable_service_monitor = true

  context                           = yamldecode(module.cluster.kubeconfig)
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  kubernetes_client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.context.users.0.user.client-key-data)

  domaine_zone_name = module.cluster.domaine_zone_name
}
