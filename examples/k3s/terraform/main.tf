module "cluster" {
  source = "git::https://github.com/camptocamp/camptocamp-devops-stack.git//modules/k3s?ref=HEAD"

  cluster_name = terraform.workspace
  node_count   = 1

  repo_url        = "https://github.com/camptocamp/camptocamp-devops-stack.git"
  target_revision = "HEAD"
}
