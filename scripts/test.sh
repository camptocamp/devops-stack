#!/bin/sh -xe

BACKDOOR_IP=$(getent hosts argocd.apps."$CLUSTER_NAME"."$BASE_DOMAIN"|cut -f1 -d' ')

# ArgoCD
curl -k -I "https://argocd.apps.$CLUSTER_NAME.$BASE_DOMAIN"
curl -k -I --resolve "argocd.apps.$BASE_DOMAIN:443:$BACKDOOR_IP" "https://argocd.apps.$BASE_DOMAIN"

# Prometheus
curl -k -I "https://prometheus.apps.$CLUSTER_NAME.$BASE_DOMAIN"
curl -k -I --resolve "prometheus.apps.$BASE_DOMAIN:443:$BACKDOOR_IP" "https://prometheus.apps.$BASE_DOMAIN"

# Alertmanager
curl -k -I "https://alertmanager.apps.$CLUSTER_NAME.$BASE_DOMAIN"
curl -k -I --resolve "alertmanager.apps.$BASE_DOMAIN:443:$BACKDOOR_IP" "https://alertmanager.apps.$BASE_DOMAIN"

# Grafana
curl -k -I "https://grafana.apps.$CLUSTER_NAME.$BASE_DOMAIN"
curl -k -I --resolve "grafana.apps.$BASE_DOMAIN:443:$BACKDOOR_IP" "https://grafana.apps.$BASE_DOMAIN"
