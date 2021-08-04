output "kubeconfig" {
  sensitive = true
  value     = module.cluster.kubeconfig
}

output "elb_ip" {
  value = module.cluster.elb_ip
}
