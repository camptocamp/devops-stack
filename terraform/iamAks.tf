# TODO: I'm not sure this is required
resource "azurerm_role_assignment" "reader" {
  scope                = format("%s/resourcegroups/%s", data.azurerm_subscription.primary.id, module.cluster.node_resource_group)
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.cert_manager.principal_id
}

resource "azurerm_role_assignment" "dns_zone_contributor" {
  scope                = data.azurerm_dns_zone.this.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.cert_manager.principal_id
}

data "azurerm_client_config" "current" {}


resource "azuread_application" "oauth2_apps" {
  count = var.oidc == null ? 1 : 0

  display_name = "oauth2-apps-${var.cluster_name}"

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
      format("https://argocd.apps.%s.%s/auth/callback", var.cluster_name, local.base_domain),
      format("https://grafana.apps.%s.%s/login/generic_oauth", var.cluster_name, local.base_domain),
      format("https://prometheus.apps.%s.%s/oauth2/callback", var.cluster_name, local.base_domain),
      format("https://alertmanager.apps.%s.%s/oauth2/callback", var.cluster_name, local.base_domain),
    ]
  }

  app_role {
    allowed_member_types = ["User"]
    description          = "ArgoCD Admins"
    display_name         = "ArgoCD Administrator"
    enabled              = true
    id                   = random_uuid.argocd_app_role.0.result
    value                = "argocd-admin"
  }

  group_membership_claims = ["ApplicationGroup"]
}

resource "random_uuid" "argocd_app_role" {
  count = var.oidc == null ? 1 : 0
}

resource "azuread_application_password" "oauth2_apps" {
  count = var.oidc == null ? 1 : 0

  application_object_id = azuread_application.oauth2_apps.0.object_id
}

data "azurerm_policy_set_definition" "restricted" {
  display_name = "Kubernetes cluster pod security restricted standards for Linux-based workloads"
}

data "azurerm_policy_set_definition" "baseline" {
  display_name = "Kubernetes cluster pod security baseline standards for Linux-based workloads"
}

resource "azurerm_policy_assignment" "baseline" {
  name                 = "${var.cluster_name}-baseline"
  scope                = format("%s/resourcegroups/%s", data.azurerm_subscription.primary.id, data.azurerm_resource_group.this.name)
  policy_definition_id = data.azurerm_policy_set_definition.baseline.id
  parameters           = <<PARAMETERS
{
  "effect": {
    "value": "deny"
  },
  "excludedNamespaces": {
    "value": [
      "aad-pod-identity",
      "kube-prometheus-stack",
      "loki-stack",
      "csi-secrets-store-provider-azure",
      "kube-system",
      "gatekeeper-system",
      "azure-arc,aad-pod-identity"
    ]
  }
}
PARAMETERS

}
resource "azurerm_user_assigned_identity" "this" {
  for_each = {
    for k, v in var.azureidentities :
    format("%s.%s", v.namespace, v.name) => v
  }
  resource_group_name = module.cluster.node_resource_group
  location            = data.azurerm_resource_group.this.location
  name                = format("%s-%s-%s", each.value.namespace, each.value.name, var.cluster_name)
}
