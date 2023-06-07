resource "azuread_application" "this" {
  display_name = format("devops-stack-apps-%s", local.platform_name)

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type = "Scope"
    }
  }

  optional_claims {
    access_token {
      additional_properties = []
      essential             = false
      name                  = "groups"
    }
    id_token {
      additional_properties = []
      essential             = false
      name                  = "groups"
    }
  }

  web {
    redirect_uris = [
      format("https://argocd.apps.%s.%s/auth/callback", local.cluster_name, azurerm_dns_zone.this.name),
      format("https://grafana.apps.%s.%s/login/generic_oauth", local.cluster_name, azurerm_dns_zone.this.name),
      format("https://prometheus.apps.%s.%s/oauth2/callback", local.cluster_name, azurerm_dns_zone.this.name),
      format("https://alertmanager.apps.%s.%s/oauth2/callback", local.cluster_name, azurerm_dns_zone.this.name),
      format("https://thanos-bucketweb.apps.%s.%s/oauth2/callback", local.cluster_name, azurerm_dns_zone.this.name),
      format("https://thanos-query.apps.%s.%s/oauth2/callback", local.cluster_name, azurerm_dns_zone.this.name),
    ]
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "ArgoCD Admins"
    display_name         = "ArgoCD Administrator"
    enabled              = true
    id                   = random_uuid.argocd_app_role_admin.result
    value                = "argocd-admin"
  }

  group_membership_claims = ["ApplicationGroup"]
}

resource "random_uuid" "argocd_app_role_admin" {
}

resource "azuread_application_password" "this" {
  application_object_id = azuread_application.this.object_id
}
