#!/bin/sh -x

CURL_CA_BUNDLE=/tmp/cert.pem

# Trust Fake LE certificate
cp /etc/ssl/cert.pem $CURL_CA_BUNDLE
curl https://letsencrypt.org/certs/fakeleintermediatex1.pem >> $CURL_CA_BUNDLE

BACKDOOR_IP=$(getent hosts argocd.apps."$CLUSTER_NAME"."$BASE_DOMAIN"|cut -f1 -d' ')

curl -I "https://argocd.apps.$CLUSTER_NAME.$BASE_DOMAIN
curl -I --resolve "argocd.apps.$BASE_DOMAIN:443:$BACKDOOR_IP" "https://argocd.apps.$BASE_DOMAIN"
