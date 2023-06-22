# Provider version
# ouboukili/argocd -> 4.0.0 otherwise argocd bootstrap latest failed due to deprecated var sur as  automated
# Load Balancer 
lb_name = "devops-stack"
zone    = "fr-par-1"
lb_type = "LB-S"

# Scaleway K8s
cluster_name        = "devops-stack"
cluster_description = "Devops-stack on cloud provider scaleway"
cluster_tags        = ["demo", "dev", "devops-stack", "test"]
kubernetes_version  = "1.27.2"
node_pools = {
  config1 = {
    node_type         = "DEV1-M"
    size              = 1
    min_size          = 0
    max_size          = 1
    autoscaling       = true
    autohealing       = true
    container_runtime = "containerd"
  }
}

# ingress
ingress_enable_service_monitor = false

# keycloak
cluster_issuer = "ca-issuer"

# cert-manager
cert_manager_enable_service_monitor = false


