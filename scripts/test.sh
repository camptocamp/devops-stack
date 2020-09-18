#!/bin/sh -xe

BACKDOOR_IP=$(getent hosts argocd.apps."$CLUSTER_NAME"."$BASE_DOMAIN"|cut -f1 -d' ')

curl -k -I "https://argocd.apps.$CLUSTER_NAME.$BASE_DOMAIN"
curl -k -I --resolve "argocd.apps.$BASE_DOMAIN:443:$BACKDOOR_IP" "https://argocd.apps.$BASE_DOMAIN"
