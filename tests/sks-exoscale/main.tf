module "cluster" {
  source = "../../modules/sks/exoscale"

  cluster_name = var.cluster_name
  zone         = "de-fra-1"

  repo_url        = var.repo_url
  target_revision = var.target_revision
}
