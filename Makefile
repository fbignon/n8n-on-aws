# Makefile para automação do projeto n8n-on-aws

init:
	@echo "📦 Inicializando Terraform..."
	./run-terraform.ps1 init

apply:
	@echo "🚀 Aplicando infraestrutura Terraform..."
	./run-terraform.ps1 apply

destroy:
	@echo "💣 Destruindo infraestrutura Terraform..."
	./run-terraform.ps1 destroy -auto-approve

backup:
	@echo "💾 Gerando backup do volume n8n_data..."
	docker run --rm -v n8n_data:/data -v $(CURDIR):/backup alpine \
	  tar -czf /backup/n8n_backup_$(shell date +%F_%H-%M).tar.gz -C /data .

restore:
	@echo "♻️ Restaurando backup mais recente para o volume n8n_data..."
	@BACKUP=$$(ls -t n8n_backup_*.tar.gz | head -n 1); \
	echo "Restaurando $$BACKUP..."; \
	docker run --rm -v n8n_data:/data -v $(CURDIR):/backup alpine \
	  sh -c "rm -rf /data/* && tar -xzf /backup/$$BACKUP -C /data"

destroy-eip:
	@echo "🧨 Liberando Elastic IP manualmente..."
	./destroy_eip_from_tf.sh

outputs:
	terraform output
