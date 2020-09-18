#!/bin/sh

CURL_CA_BUNDLE=/tmp/cert.pem

# Trust Fake LE certificate
cp /etc/ssl/cert.pem $CURL_CA_BUNDLE
curl https://letsencrypt.org/certs/fakeleintermediatex1.pem >> $CURL_CA_BUNDLE

curl -I "https://argocd.apps.$CLUSTER_NAME.$BASE_DOMAIN"
curl -I --resolve "argocd.apps.$BASE_DOMAIN:443:$(getent hosts argocd.apps.$CLUSTER_NAME.$BASE_DOMAIN|cut -f1 -d' ')" "https://argocd.apps.$BASE_DOMAIN"
