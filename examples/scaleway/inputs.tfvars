# ###################################################
# Input for module which creates the scaleway cluster 
# ###################################################
cluster_name        = "devops-stack"
cluster_description = "Devops-stack on cloud provider scaleway"
cluster_tags        = ["demo", "dev", "devops-stack", "test", ]
cluster_type        = "multicloud"
kubernetes_version  = "1.29.1"
admission_plugins   = ["PodNodeSelector", ]
node_pools = {
  config1 = {
    node_type           = "DEV1-L"
    size                = 2
    min_size            = 2
    max_size            = 2
    autoscaling         = true
    autohealing         = true
    container_runtime   = "containerd"
    wait_for_pool_ready = true
  }
}

# #########################
# Additional cluster config
# #########################
base_domain = "gs-fr-dev.camptocamp.com"
lb_name     = "devops-stack"
zone        = "fr-par-1"
lb_type     = "LB-S"

# Ingress
ingress_enable_service_monitor = false

# Keycloak
cluster_issuer = "ca-issuer"

# Cert-manager
cert_manager_enable_service_monitor = false
