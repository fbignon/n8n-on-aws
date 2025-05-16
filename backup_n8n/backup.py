import requests
import os
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()
url = os.getenv("N8N_URL")
user = os.getenv("N8N_USER")
pwd = os.getenv("N8N_PASS")

auth = (user, pwd)

res = requests.get(f"{url}/rest/workflows", auth=auth)
res.raise_for_status()
workflows = res.json()["data"]

timestamp = datetime.now().strftime("%Y-%m-%d_%H-%M")
backup_dir = f"n8n_backup_{timestamp}"
os.makedirs(backup_dir, exist_ok=True)

for wf in workflows:
    wf_id = wf["id"]
    wf_name = wf["name"].replace(" ", "_")
    wf_data = requests.get(f"{url}/rest/workflows/{wf_id}", auth=auth).json()
    with open(f"{backup_dir}/{wf_id}_{wf_name}.json", "w", encoding="utf-8") as f:
        f.write(requests.utils.json.dumps(wf_data, indent=2))

print(f"✅ Backup completo: {len(workflows)} workflows salvos em ./{backup_dir}")
