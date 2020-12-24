module "cluster" {
  source  = "camptocamp/k3s/libvirt"
  version = "0.3.0"

  cluster_name = var.cluster_name
  k3os_version = var.k3os_version
  node_count   = var.node_count

  server_memory = var.server_memory
  agent_memory  = var.agent_memory
}
