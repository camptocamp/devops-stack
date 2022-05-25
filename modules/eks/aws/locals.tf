locals {
  helm_values = var.enable_cluster_autoscaler ? {
    cluster-autoscaler = {
      awsRegion = data.aws_region.current.name
      rbac = {
        create = true
        serviceAccount = {
          name = "cluster-autoscaler"
          annotations = {
            "eks.amazonaws.com/role-arn" = var.cluster_autoscaler_role_arn
          }
        }
      }
      autoDiscovery = {
        clusterName = var.cluster_name
        enabled = true
      }
    }
  } : {}
}
