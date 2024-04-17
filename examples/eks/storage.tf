resource "aws_s3_bucket" "thanos_metrics_storage" {
  bucket = format("thanos-metrics-storage-%s", module.eks.cluster_name)

  force_destroy = true

  tags = {
    Description = "Thanos metrics storage"
    Cluster     = module.eks.cluster_name
  }
}

resource "aws_s3_bucket" "loki_logs_storage" {
  bucket = format("loki-logs-storage-%s", module.eks.cluster_name)

  force_destroy = true

  tags = {
    Description = "Loki logs storage"
    Cluster     = module.eks.cluster_name
  }
}
