locals {
  base_domain                       = var.base_domain
  all_domains                       = toset(compact(distinct(concat([var.base_domain], var.other_domains))))
  kubernetes_host                   = local.context.clusters.0.cluster.server
  kubernetes_cluster_ca_certificate = base64decode(local.context.clusters.0.cluster.certificate-authority-data)
  kubernetes_client_certificate     = base64decode(local.context.users.0.user.client-certificate-data)
  kubernetes_client_key             = base64decode(local.context.users.0.user.client-key-data)

  context                           = yamldecode(module.cluster.kubeconfig)
  kubeconfig                        = module.cluster.kubeconfig

  ovh_s3_access_key_id     = ovh_cloud_project_user_s3_credential.s3_op_creds.access_key_id
  ovh_s3_secret_access_key = ovh_cloud_project_user_s3_credential.s3_op_creds.secret_access_key

  keycloak_user_map = { for username, infos in var.keycloak_users : username => merge(infos, tomap({ password = random_password.keycloak_passwords[username].result })) }

  oidc = var.oidc != null ? var.oidc : {
    issuer_url    = format("https://keycloak.apps.%s.%s/auth/realms/devops-stack", var.cluster_name, local.base_domain)
    oauth_url     = format("https://keycloak.apps.%s.%s/auth/realms/devops-stack/protocol/openid-connect/auth", var.cluster_name, local.base_domain)
    token_url     = format("https://keycloak.apps.%s.%s/auth/realms/devops-stack/protocol/openid-connect/token", var.cluster_name, local.base_domain)
    api_url       = format("https://keycloak.apps.%s.%s/auth/realms/devops-stack/protocol/openid-connect/userinfo", var.cluster_name, local.base_domain)
    client_id     = "devops-stack-applications"
    client_secret = random_password.clientsecret.result
    oauth2_proxy_extra_args = [
      "--insecure-oidc-skip-issuer-verification=true",
      "--ssl-insecure-skip-verify=true",
    ]
  }
}
