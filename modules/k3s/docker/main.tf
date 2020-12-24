module "cluster" {
  source  = "camptocamp/k3s/docker"
  version = "0.6.0"

  network_name = "bridge"
  cluster_name = var.cluster_name
  k3s_version  = var.k3s_version
  node_count   = var.node_count
  server_config = [
    "--disable", "traefik",
    "--disable", "metrics-server",
  ]
}
