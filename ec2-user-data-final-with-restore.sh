
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

USERNAME=ubuntu
HOME_DIR="/home/$USERNAME"

# Atualiza pacotes
apt update -y

# Instala Docker e utilitários
apt install -y docker.io git curl cron s3fs awscli certbot python3-certbot-nginx unzip software-properties-common

# Adiciona o usuário ubuntu ao grupo docker
usermod -aG docker $USERNAME

# Inicia e habilita Docker
systemctl start docker
systemctl enable docker

# Instala docker-compose manualmente
curl -SL https://github.com/docker/compose/releases/download/v2.24.7/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Cria estrutura do projeto
mkdir -p $HOME_DIR/n8n-on-aws
chown -R $USERNAME:$USERNAME $HOME_DIR/n8n-on-aws

cd $HOME_DIR
git clone https://github.com/fbignon/n8n-on-aws.git || echo "Repositório já clonado"
chown -R $USERNAME:$USERNAME n8n-on-aws
cd n8n-on-aws

# Criação correta da estrutura usada pelo nginx e certbot
mkdir -p nginx/certbot/etc/letsencrypt
mkdir -p nginx/certbot/var/lib/letsencrypt
mkdir -p nginx/certbot/var/log
mkdir -p nginx/certbot/www/.well-known/acme-challenge

# Corrige permissões
chown -R $USERNAME:$USERNAME nginx/certbot

# Desativa nginx nativo da EC2
systemctl stop nginx || true
systemctl disable nginx || true

# Cria volume nomeado para n8n
docker volume create n8n_data

# === Restauração de backup (se houver) ===
BACKUP_FILE=$(find . -maxdepth 1 -name "n8n_backup_*.tar.gz" | sort | tail -n 1)
if [ -f "$BACKUP_FILE" ]; then
  echo "🟡 Backup encontrado: $BACKUP_FILE"
  docker run --rm -v n8n_data:/data -v $PWD:/backup alpine sh -c "rm -rf /data/* && tar -xzf /backup/$(basename $BACKUP_FILE) -C /data"
else
  echo "⚠️ Nenhum backup encontrado para restaurar."
fi

# Sobe o nginx temporariamente para obter certificado
sudo -u $USERNAME docker-compose -f docker-compose-https.yml up -d nginx
sleep 10

# Executa certbot (gera certificado)
docker run --rm \
  -v $PWD/nginx/certbot/etc/letsencrypt:/etc/letsencrypt \
  -v $PWD/nginx/certbot/www:/var/www/certbot \
  certbot/certbot certonly --webroot --webroot-path=/var/www/certbot \
  --email contato@globalstorebr.com --agree-tos --no-eff-email \
  -d n8n.globalstorebr.com || echo "⚠️ Certbot falhou, possivelmente DNS ainda não propagou."

# Sobe tudo com HTTPS (nginx + n8n)
sudo -u $USERNAME docker-compose -f docker-compose-https.yml up -d

# === Cronjob para renovar automaticamente ===
(crontab -l 2>/dev/null; echo "0 3 */2 * * docker run --rm \
  -v $HOME_DIR/n8n-on-aws/nginx/certbot/etc/letsencrypt:/etc/letsencrypt \
  -v $HOME_DIR/n8n-on-aws/nginx/certbot/www:/var/www/certbot \
  certbot/certbot renew --webroot --webroot-path=/var/www/certbot && \
  docker exec n8n-on-aws-nginx-1 nginx -s reload") | crontab -

echo '✅ Instância configurada com Docker, n8n com HTTPS, restauração de backup e cron de renovação automática.'
