#!/bin/sh -xe

mkdir -p "$HOME/bin"
wget https://github.com/argoproj/argo-cd/releases/download/v1.7.6/argocd-linux-amd64 -O "$HOME/bin/argocd"
chmod +x "$HOME/bin/argocd"
