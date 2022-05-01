cluster_name = "pts-appsre-gnxtgen-mgmtpoc-aks"
cluster_issuer = "letsencrypt-prod"
#argocd = "domain"
base_domain = "gnxtgen.ncrpoc"
repo_url = "https://github.com/argoproj/argocd-example-apps"
resource_group_name = "pts-appsre-gnxtgen-mgmtpoc-rg"
target_revision = "HEAD"
vnet_subnet_id = "pts-appsre-gnxtgen-mgmtpoc-snet"
#https://www.terraform.io/language/functions/dirname
kubeconfig =  templatefile("${path.module}/values.tmpl.yaml",
      {
        subscription_id                              = split("/", data.azurerm_subscription.primary.id)[2]
        resource_group_name                          = var.resource_group_name
        base_domain                                  = local.base_domain
        cert_manager_resource_id                     = azurerm_user_assigned_identity.cert_manager.id
        cert_manager_client_id                       = azurerm_user_assigned_identity.cert_manager.client_id
        azure_dns_label_name                         = local.azure_dns_label_name
        kube_prometheus_stack_prometheus_resource_id = azurerm_user_assigned_identity.kube_prometheus_stack_prometheus.id
        kube_prometheus_stack_prometheus_client_id   = azurerm_user_assigned_identity.kube_prometheus_stack_prometheus.client_id
        loki_container_name                          = azurerm_storage_container.loki.name
        loki_account_name                            = azurerm_storage_account.this.name
        loki_account_key                             = azurerm_storage_account.this.primary_access_key
        azureidentities                              = local.azureidentities
        namespaces                                   = local.namespaces
       }
     )