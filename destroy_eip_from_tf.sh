#!/bin/bash

# Requer: terraform instalado e 'terraform output' acessível
#         awscli configurado com credenciais válidas

echo "🔄 Lendo prefixo do projeto a partir do Terraform..."

# Obtem project_prefix a partir de terraform output
PROJECT_PREFIX=$(terraform output -raw project_prefix 2>/dev/null)

if [ -z "$PROJECT_PREFIX" ]; then
  echo "❌ Não foi possível obter project_prefix via 'terraform output'."
  echo "💡 Verifique se ele está definido em outputs.tf e o estado está aplicado."
  exit 1
fi

echo "🔍 Procurando Elastic IP com tag Name contendo: $PROJECT_PREFIX"

# Busca AllocationId com tag Name que contenha o prefixo
EIP_ID=$(aws ec2 describe-addresses --query "Addresses[?Tags[?Key=='Name' && contains(Value, '$PROJECT_PREFIX')]].AllocationId" --output text)

if [ -z "$EIP_ID" ]; then
  echo "❌ Nenhum Elastic IP encontrado com a tag apropriada."
  exit 1
fi

echo "⚠️ Encontrado AllocationId: $EIP_ID"
read -p "Deseja realmente liberar este Elastic IP? [s/N] " CONFIRM

if [[ "$CONFIRM" =~ ^[sS]$ ]]; then
  aws ec2 release-address --allocation-id "$EIP_ID"
  echo "✅ Elastic IP liberado com sucesso."
else
  echo "❌ Cancelado pelo usuário."
fi
