#!/bin/bash
yum update -y
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
chkconfig docker on

# Instala Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clona e inicia o n8n
cd /home/ec2-user
yum install git -y
git clone https://github.com/<seu-repo>/n8n-on-aws.git
cd n8n-on-aws
docker-compose up -d
