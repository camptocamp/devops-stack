locals {
  iat = 1605854613 # An arbitrary Unix timestamp before than now

  argocd_accounts_pipeline_tokens = jsonencode(
    [
      {
        id  = random_uuid.accounts_pipeline_token_id.result
        iat = local.iat
      }
    ]
  )
}

resource "random_uuid" "accounts_pipeline_token_id" {}

resource "helm_release" "argocd" {
  name              = "argocd"
  chart             = "${path.module}/../../argocd/argocd"
  namespace         = "argocd"
  dependency_update = true
  create_namespace  = true

  values = [
    file("${path.module}/../../argocd/argocd/values.yaml"),
    <<EOT
    argo-cd:
      configs:
        secret:
          extra:
            accounts.pipeline.tokens: '${local.argocd_accounts_pipeline_tokens}'
    EOT
  ]
}
