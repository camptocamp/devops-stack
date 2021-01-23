module "cluster" {
  source  = "camptocamp/k3s/docker"
  version = "0.7.1"

  network_name = "bridge"
  cluster_name = var.cluster_name
  k3s_version  = var.k3s_version
  node_count   = var.node_count
  server_config = [
    "--disable", "traefik",
    "--disable", "metrics-server",
  ]

  registry_mirrors = {
    "docker.io" = [
      "REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io",
    ],
    "quay.io" = [
      "REGISTRY_PROXY_REMOTEURL=https://quay.io/repository",
      "REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true",
    ],
    "gcr.io" = [
      "REGISTRY_PROXY_REMOTEURL=https://gcr.io",
    ],
    "us.gcr.io" = [
      "REGISTRY_PROXY_REMOTEURL=https://us.gcr.io",
    ],
  }
}
