resource "aws_cognito_user_pool" "pool" {
  name = module.eks.cluster_name
}

resource "aws_cognito_user_pool_domain" "pool_domain" {
  domain       = module.eks.cluster_name
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_user_group" "argocd_admin_group" {
  name         = "argocd-admin"
  user_pool_id = aws_cognito_user_pool.pool.id
  description  = "Users with admin access to Argo CD"
}

resource "random_string" "cognito_admin_password" {
  length = 25
}

resource "aws_cognito_user" "admin" {
  user_pool_id = aws_cognito_user_pool.pool.id

  username = "admin"
  password = random_string.cognito_admin_password.result

  message_action = "SUPPRESS" # Do not send welcome message since password is hardcoded and email is non-existant

  attributes = {
    email          = "admin@example.org"
    email_verified = true
  }
}

resource "aws_cognito_user_in_group" "add_admin_argocd_admin" {
  user_pool_id = aws_cognito_user_pool.pool.id
  group_name   = aws_cognito_user_group.argocd_admin_group.name
  username     = aws_cognito_user.admin.username
}


module "oidc" {
  source = "git::https://github.com/camptocamp/devops-stack-module-oidc-aws-cognito.git?ref=v1.0.0"

  cluster_name = module.eks.cluster_name
  base_domain  = module.eks.base_domain

  cognito_user_pool_id     = aws_cognito_user_pool.pool.id
  cognito_user_pool_domain = aws_cognito_user_pool_domain.pool_domain.domain

  depends_on = [module.eks]
}

