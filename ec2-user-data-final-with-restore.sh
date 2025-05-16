#!/bin/bash
set -e

USERNAME=ubuntu
HOME_DIR="/home/$USERNAME"

# Atualiza pacotes
apt update -y && apt upgrade -y

# Instala Docker e Docker Compose
apt install -y docker.io git curl cron
usermod -aG docker $USERNAME
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu


# Cria estrutura de diretórios
mkdir -p $HOME_DIR/n8n-on-aws
chown -R $USERNAME:$USERNAME $HOME_DIR/n8n-on-aws

# Clona o repositório com os arquivos de configuração
cd $HOME_DIR
git clone https://github.com/fbignon/n8n-on-aws.git || echo "Repositório já clonado"
chown -R $USERNAME:$USERNAME n8n-on-aws
cd n8n-on-aws

# Cria diretórios de volume persistente e certbot
mkdir -p nginx/certbot/conf
mkdir -p nginx/certbot/www

# Cria volume nomeado
docker volume create n8n_data

# === Restaurar backup local se houver ===
BACKUP_FILE=$(find . -maxdepth 1 -name "n8n_backup_*.tar.gz" | sort | tail -n 1)
if [ -f "$BACKUP_FILE" ]; then
  echo "🟡 Backup encontrado: $BACKUP_FILE"
  docker run --rm -v n8n_data:/data -v $PWD:/backup alpine     sh -c "rm -rf /data/* && tar -xzf /backup/$(basename $BACKUP_FILE) -C /data"
else
  echo "⚠️ Nenhum backup encontrado para restaurar."
fi

# Gera certificados com certbot (vai falhar se o DNS não estiver propagado)
docker-compose -f docker-compose-https.yml up -d nginx
sleep 10
docker run --rm -v $PWD/nginx/certbot/conf:/etc/letsencrypt -v $PWD/nginx/certbot/www:/var/www/certbot certbot/certbot certonly --webroot --webroot-path=/var/www/certbot --email contato@globalstorebr.com --agree-tos --no-eff-email -d n8n.globalstorebr.com || echo "⚠️ Certbot falhou, possivelmente DNS ainda não propagou."

# Sobe os serviços com HTTPS
docker-compose -f docker-compose-https.yml up -d

# === Cron job para renovação automática do certificado ===
(crontab -l 2>/dev/null; echo "0 3 */2 * * docker run --rm \
  -v $HOME_DIR/n8n-on-aws/nginx/certbot/conf:/etc/letsencrypt \
  -v $HOME_DIR/n8n-on-aws/nginx/certbot/www:/var/www/certbot \
  certbot/certbot renew --webroot --webroot-path=/var/www/certbot && \
  docker exec nginx nginx -s reload") | crontab -

echo '✅ Instância configurada com Docker, n8n HTTPS, restauração de backup e cron automático.'
