#!/bin/bash

# Atualiza pacotes e instala Docker
apt-get update -y
apt-get install -y docker.io git curl

# Inicia e habilita o serviço Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Instala Docker Compose (v2 mais recente)
curl -SL https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-x86_64 \
    -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clona repositório com docker-compose.yml (ou use cp se já copiou via Terraform)
cd /home/ubuntu
git clone https://github.com/SEU_USUARIO/n8n-on-aws.git
cd n8n-on-aws
chown -R ubuntu:ubuntu /home/ubuntu/n8n-on-aws

# Sobe o serviço n8n
sudo -u ubuntu docker-compose up -d
