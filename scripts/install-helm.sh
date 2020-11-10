#!/bin/sh -xe

mkdir -p "$HOME/bin"
wget https://get.helm.sh/helm-v3.4.0-linux-amd64.tar.gz -O -| tar xz linux-amd64/helm -O > "$HOME/bin/helm"
chmod +x "$HOME/bin/helm"
