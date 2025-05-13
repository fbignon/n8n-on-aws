FROM hashicorp/terraform:1.11.3

# Diretório de trabalho no container
WORKDIR /workspace

# Copia o script de entrada
COPY terraform.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
