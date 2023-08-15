output "ingress_domain" {
  description = "The domain to use for accessing the applications."
  value       = "${module.eks.cluster_name}.${module.eks.base_domain}"
}

output "devops_admins" {
  description = "Map containing the usernames and emails of the users created in the Cognito pool."
  value       = module.oidc.devops_stack_admins
  sensitive   = true
}
