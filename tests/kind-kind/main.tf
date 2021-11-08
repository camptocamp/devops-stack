module "cluster" {
  source = "../../modules/kind/kind"

  cluster_name = var.cluster_name

  repo_url        = var.repo_url
  target_revision = var.target_revision

  api_server_address = var.api_server_address
}
