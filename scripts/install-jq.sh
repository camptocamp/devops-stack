#!/bin/sh -xe

mkdir -p "$HOME/bin"
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O "$HOME/bin/jq"
chmod +x "$HOME/bin/jq"
