#!/bin/bash

export DEBIAN_FRONTEND=noninteractive


# Função para instalar Docker e Compose no Amazon Linux 2
install_amazon_linux() {
  echo "🔧 Detecção: Amazon Linux"
  yum update -y
  amazon-linux-extras install docker -y
  service docker start
  usermod -aG docker ec2-user
  chkconfig docker on

  curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  yum install -y git
  HOME_DIR="/home/ec2-user"
  USERNAME="ec2-user"
}

# Função para instalar Docker e Compose no Ubuntu
install_ubuntu() {
  echo "🔧 Detecção: Ubuntu"
  apt-get update -y
  apt-get install -y docker.io git curl s3fs awscli
  systemctl start docker
  systemctl enable docker
  usermod -aG docker ubuntu

  curl -SL https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-x86_64 \
    -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  HOME_DIR="/home/ubuntu"
  USERNAME="ubuntu"
}

# Detecta distribuição
if grep -qi "Amazon Linux" /etc/os-release; then
  install_amazon_linux
elif grep -qi "Ubuntu" /etc/os-release; then
  install_ubuntu
else
  echo "❌ Distribuição não suportada."
  exit 1
fi


# Montar bucket S3 como volume persistente
BUCKET_NAME=n8n-volume-persistencia
sudo usermod -aG docker ubuntu
mkdir -p /mnt/n8n-data

# Monta o bucket com as opções corretas
sudo s3fs $BUCKET_NAME /mnt/n8n-data \
  -o iam_role=auto \
  -o allow_other \
  -o uid=1000,gid=1000 \
  -o use_path_request_style \
  -o url=https://s3.amazonaws.com

# AGORA sim, aplique permissões no volume montado
sudo chown -R 1000:1000 /mnt/n8n-data
sudo chmod -R u+rwX /mnt/n8n-data

# Clonar projeto e subir Docker
cd $HOME_DIR
git clone https://github.com/fbignon/n8n-on-aws.git || echo "⚠️ Repositório já clonado"
cd n8n-on-aws

chown -R $USERNAME:$USERNAME $HOME_DIR/n8n-on-aws
sudo -u $USERNAME docker-compose up -d
