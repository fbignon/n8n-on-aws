import json
import os
import datetime
import requests
from dotenv import load_dotenv

if not os.path.exists('.env'):
    print("⚠️ Arquivo .env não encontrado. Por favor, configure conforme o .env.example")

load_dotenv()

N8N_HOST = os.getenv("N8N_API_URL")
N8N_API_KEY = os.getenv("N8N_API_KEY")
BACKUP_DIR = "./backup_n8n/backups"

os.makedirs(BACKUP_DIR, exist_ok=True)

headers = {
    "X-N8N-API-KEY": N8N_API_KEY,
    "accept": "application/json"
}

print("Executando backup via API REST...")

try:
    res = requests.get(f"{N8N_HOST}/api/v1/workflows?active=true", headers=headers)
    res.raise_for_status()
    workflows = res.json().get("data", [])
except Exception as e:
    print(f"Erro ao obter workflows: {e}")
    exit(1)

if not workflows:
    print("Nenhum workflow ativo encontrado.")
    exit(0)

timestamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
backup_file = os.path.join(BACKUP_DIR, f"n8n-backup-{timestamp}.json")

with open(backup_file, 'w', encoding='utf-8') as f:
    json.dump(workflows, f, ensure_ascii=False, indent=2)

print(f"Backup concluído com sucesso: {backup_file}")
