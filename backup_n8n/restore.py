import os
import json
import requests
from dotenv import load_dotenv

# Carregar variáveis do .env

if not os.path.exists('.env'):
    print("⚠️ Arquivo .env não encontrado. Por favor, configure conforme o .env.example")

load_dotenv()

N8N_API_KEY = os.getenv("N8N_API_KEY")
N8N_API_URL = os.getenv("N8N_API_URL")

backup_dir = './backup_n8n/backups'
backup_files = sorted(
    [f for f in os.listdir(backup_dir) if f.endswith('.json')],
    reverse=True
)

if not backup_files:
    print("Nenhum arquivo de backup encontrado.")
    exit(1)

latest_backup = os.path.join(backup_dir, backup_files[0])

print(f"Restaurando backup do arquivo: {latest_backup}")

# Ler o arquivo de backup
with open(latest_backup, 'r', encoding='utf-8') as f:
    workflows = json.load(f)

headers = {
    'X-N8N-API-KEY': N8N_API_KEY,
    'Content-Type': 'application/json',
    'accept': 'application/json'
}

for workflow in workflows:
    # Criar novo dicionário ignorando os campos read-only
    workflow_data = {
        'name': workflow.get('name'),
        'nodes': workflow.get('nodes'),
        'connections': workflow.get('connections'),
        'settings': workflow.get('settings', {})
    }

    print(f"Restaurando workflow: {workflow_data['name']}")

    try:
        res = requests.post(
            f"{N8N_API_URL}/api/v1/workflows",
            headers=headers,
            json=workflow_data
        )

        if res.status_code in [200, 201]:
            print(f"✅ Workflow '{workflow_data['name']}' restaurado com sucesso.")
        else:
            print(f"❌ Erro ao restaurar workflow '{workflow_data['name']}': {res.status_code} - {res.text}")

    except requests.exceptions.RequestException as e:
        print(f"❌ Erro de conexão ao restaurar workflow '{workflow_data['name']}': {e}")
