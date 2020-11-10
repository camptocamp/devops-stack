#!/bin/sh -xe

mkdir -p "$HOME/bin"
wget https://download.docker.com/linux/static/stable/x86_64/docker-19.03.9.tgz -O -|tar xz docker/docker -O > "$HOME/bin/docker"
chmod +x "$HOME/bin/docker"
