#!/bin/bash

sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    docker.io docker-compose make curl lftp openssh-server

sudo usermod -aG docker $USER
sudo systemctl enable --now ssh

echo "127.0.0.1 ibeltran.42.fr" | sudo tee -a /etc/hosts