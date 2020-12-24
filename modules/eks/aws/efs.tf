module "efs" {
  count  = var.enable_efs ? 1 : 0
  source = "camptocamp/efs/aws"

  name                     = var.cluster_name
  subnet_id                = tolist(data.aws_subnet_ids.private.ids)[0]
  vpc_id                   = data.aws_vpc.this.id
  source_security_group_id = module.cluster.worker_security_group_id
}
