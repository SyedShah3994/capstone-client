#!/bin/bash
set -e

fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

apt-get update -y
apt-get install -y docker.io docker-compose-v2 git curl
systemctl enable --now docker
usermod -aG docker ubuntu