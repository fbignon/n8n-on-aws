#Get-ChildItem *.ps1 | Unblock-File
Clear-Host
do {
    # Verifica a política efetiva de execução do PowerShell
  $effectivePolicy = Get-ExecutionPolicy -Scope Process
  if ($effectivePolicy -eq "Undefined") {
    $effectivePolicy = Get-ExecutionPolicy
  }

  if ($effectivePolicy -eq "Restricted") {
    Write-Host "`n⚠️ Sua política de execução está bloqueando scripts (.ps1)."
    Write-Host "Para liberar temporariamente, execute no PowerShell:"
    Write-Host ""
    Write-Host "    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass"
    Write-Host ""
    Write-Host "Depois, execute novamente:"
    Write-Host "    ./menu-n8n.ps1`n"
    exit
  }

  # Garante que o script de liberar EIP está desbloqueado
  if (Test-Path "./destroy_eip_from_tf.ps1") {
    Unblock-File -Path "./destroy_eip_from_tf.ps1" -ErrorAction SilentlyContinue
  }
  
  Write-Host "==============================="
  Write-Host "  n8n-on-aws - Menu Principal"
  Write-Host "===============================`n"
  Write-Host "1. Terraform Init"
  Write-Host "2. Terraform Apply"
  Write-Host "3. Terraform Destroy"
  Write-Host "4. Backup Volume"
  Write-Host "5. Restaurar Ultimo Backup"
  Write-Host "6. Ver Outputs do Terraform"
  Write-Host "7. Liberar Elastic IP"
  Write-Host "8. Gerar comando para conexao remota"
  Write-Host "9. Backup via API (Python Script)"
  Write-Host "10. Restaurar Backup via API (Python Script)"
  Write-Host "0. Sair`n"
  $option = Read-Host "Escolha uma opcao"

  switch ($option) {
    "1" { ./run-terraform.ps1 init }
    "2" { ./run-terraform.ps1 apply -auto-approve }

    "3" {
      Write-Host "🔍 Buscando recursos no Terraform state para destruir (exceto EIP protegido)..."

      $stateRaw = ./run-terraform.ps1 state list
      $targets = $stateRaw | Where-Object { $_ -match '^aws_' -and $_ -notmatch '^aws_eip' }

      if ($targets.Count -eq 0) {
        Write-Host "❗ Nada a destruir (exceto Elastic IP protegido)."
      } else {
        $targetArgs = $targets | ForEach-Object { "-target=$_" }
        $commandArgs = @("destroy") + $targetArgs + "-auto-approve"

        Write-Host "`n⚙️ Executando: terraform destroy $($targetArgs -join ' ') -auto-approve`n"

        & "./run-terraform.ps1" @commandArgs
      }

      Pause
    }


    "4" {
      if (-not (Test-Path "${PWD}\backups")) {
        New-Item -ItemType Directory -Path "${PWD}\backups"
      }

      $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
      docker run --rm --volumes-from n8n -v "${PWD}\backups:/backup" alpine \
      sh -c "tar -czf /backup/n8n-backup-$timestamp.tar.gz -C /home/node .n8n"
    }

    "5" {
      $latest = Get-ChildItem -Path . -Filter "n8n-backup-*.tar.gz" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
      if ($latest) {
        docker run --rm -v n8n_data:/data -v ${PWD}:/backup alpine `
          sh -c "rm -rf /data/* && tar -xzf /backup/$($latest.Name) -C /data"
        Write-Host "`n✅ Backup restaurado: $($latest.Name)`n"
      } else {
        Write-Host "`n❌ Nenhum backup encontrado.`n"
      }
    }

    "6" { ./run-terraform.ps1 output }

    "7" {
      Write-Host "Liberando Elastic IP com segurança..."
      ./destroy_eip_from_tf.ps1
    }


    "8" {
      Write-Host "`n🔐 Corrigindo erro SSH (known_hosts)..."

      # Executa o script e filtra apenas a linha com IP válido
      $rawOutput = & "./run-terraform.ps1" output -raw n8n_elastic_ip 2>$null
      $ip = $rawOutput | Select-String -Pattern '^\d{1,3}(\.\d{1,3}){3}$' | Select-Object -ExpandProperty Line

      if ($ip) {
        $hostname = "ec2-" + ($ip -replace '\.', '-') + ".us-east-2.compute.amazonaws.com"

        Write-Host "➡️ Resetando entrada SSH: $hostname"
        ssh-keygen -R $hostname | Out-Null

        Write-Host "`n[OK] Entrada atualizada. Agora você pode usar:"
        Write-Host "ssh -i 'n8n-key.pem' ubuntu@$hostname`n"
      }
      else {
        Write-Host "`n⚠️ Não foi possível obter o IP do Terraform. Verifique se a infraestrutura está ativa."
      }

      Pause
    }

    "9" {
      Write-Host "Executando backup via Python (API REST)..."
      python ./backup_n8n/backup.py
      Pause
    }

    "10" {
      Write-Host "Executando restore via Python (API REST)..."
      & python ./backup_n8n/restore.py
    }

    default { Write-Host "`n❌ Opção inválida, tente novamente.`n" }
  }

  Write-Host "`n"
  Pause
  Clear-Host
} while ($option -ne "0")
