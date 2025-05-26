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

  function Get-InstanceInfo {
    $rawOutput = & "./run-terraform.ps1" output -raw n8n_elastic_ip 2>$null
    $global:instance_ip = $rawOutput | Select-String -Pattern '^\d{1,3}(\.\d{1,3}){3}$' | Select-Object -ExpandProperty Line

    if ($global:instance_ip) {
        $global:hostname = "ec2-" + ($global:instance_ip -replace '\.', '-') + ".us-east-2.compute.amazonaws.com"
    } else {
        Write-Host "❌ Não foi possível obter o IP do Terraform. Verifique se a infraestrutura está ativa."
        return $false
    }

    $global:key_path = 'n8n-key.pem'

    return $true
}

function Wait-CloudInitComplete {
    Get-InstanceInfo

    Write-Host "`n🕐 Aguardando inicialização completa da instância EC2..."

    $isComplete = $false

    while (-not $isComplete) {
        try {
            $logContent = ssh -o StrictHostKeyChecking=no -i $key_path ubuntu@$hostname "tail -n 20 /var/log/cloud-init-output.log" 2>$null

            if ($logContent -match "Cloud-init v.*finished at") {
                Write-Host "✅ Cloud-init finalizado com sucesso!"
                $isComplete = $true
            } else {
                Write-Host "⏳ Aguardando... Próxima verificação em 10 segundos..."
                Start-Sleep -Seconds 45
            }
        } catch {
            Write-Host "⚠️ Falha ao conectar via SSH. Tentando novamente em 10 segundos..."
            Start-Sleep -Seconds 45
        }
    }
}
  

  Write-Host "==============================="
  Write-Host "  n8n-on-aws - Menu Principal"
  Write-Host "===============================`n"
  Write-Host "1. Terraform Init"
  Write-Host "2. Terraform Apply"
  Write-Host "3. Terraform Destroy"
  Write-Host "4. Ver Outputs do Terraform"
  Write-Host "5. Liberar Elastic IP"
  Write-Host "6. Resetar SSH e Gerar comando para conexao remota"
  Write-Host "7. Backup via API (Python Script)"
  Write-Host "8. Restaurar Backup via API (Python Script)"
  Write-Host "9. Backup Credenciais (via SSH)"
  Write-Host "10. Restaurar Credenciais (via SSH)"
  Write-Host "0. Sair`n"
  $option = Read-Host "Escolha uma opcao"

  switch ($option) {
    "1" { ./run-terraform.ps1 init }
    
    "2" {
    # Insere o .env no git antes do deploy
    Write-Host "`n🧹 Inserindo .env no controle de versão..."
    git status
    git add .
    git commit -m "Insere .env no deploy"
    git push origin main

    Write-Host "`n🚀 Executando Terraform Apply..."
    ./run-terraform.ps1 apply  -auto-approve

    Write-Host "`n✅ Terraform Apply concluído."

    # Aguarda Cloud-init finalizar
    Wait-CloudInitComplete -ip $instance_ip -key_path $key_path

    # Após a instância estar 100% operacional, remove o .env do git
    Write-Host "`n🧹 Removendo .env do controle de versão..."
    git rm --cached .env
    git rm --cached backup_n8n/.env
    git status
    git commit -m "Remove .env após deploy"
    git push
    Write-Host "✅ .env removido do Git e alterações enviadas."
    Pause
}


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

    "4" { ./run-terraform.ps1 output }

    "5" {
      Write-Host "Liberando Elastic IP com segurança..."
      ./destroy_eip_from_tf.ps1
    }


    "6" {
      Write-Host "`n🔐 Corrigindo erro SSH (known_hosts)..."

      Get-InstanceInfo

      if ($instance_ip) {
        $hostname = "ec2-" + ($instance_ip -replace '\.', '-') + ".us-east-2.compute.amazonaws.com"

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

    "7" {
      Write-Host "Executando backup via Python (API REST)..."
      python ./backup_n8n/backup.py
      Pause
    }

    "8" {
      Write-Host "Executando restore via Python (API REST)..."
      & python ./backup_n8n/restore.py
    }

   "9" {
    Write-Host "`n🚀 Iniciando backup das credenciais via SSH..."
    
    if (Get-InstanceInfo) {
        $container_backup = ".n8n/credentials-backup.json"
        $remote_backup = "/home/ubuntu/credentials-backup.json"
        $local_backup = ".\backup_n8n\backups\credentials-backup.json"

        ssh -i $key_path ubuntu@$hostname "docker exec n8n n8n export:credentials --all --output=$container_backup && docker cp n8n:/home/node/$container_backup $remote_backup"

        if ($LASTEXITCODE -eq 0) {
            scp -i $key_path ubuntu@${hostname}:$remote_backup $local_backup
            Write-Host "✅ Backup das credenciais concluído: $local_backup"
        } else {
            Write-Host "❌ Erro ao gerar ou copiar o backup remoto."
        }
    }

    Pause
}


"10" {
    Write-Host "`n🚀 Iniciando restauração das credenciais via SSH..."

    if (Get-InstanceInfo) {
        $container_backup = ".n8n/credentials-backup.json"
        $remote_backup = "/home/ubuntu/credentials-backup.json"
        $local_backup = ".\backup_n8n\backups\credentials-backup.json"

        if (Test-Path $local_backup) {
            # Envia o arquivo para a instância
            scp -i $key_path $local_backup ubuntu@${hostname}:$remote_backup

            if ($LASTEXITCODE -eq 0) {
                # Move o arquivo para dentro do container e executa o import
                ssh -i $key_path ubuntu@$hostname "docker cp $remote_backup n8n:/home/node/$container_backup && docker exec n8n n8n import:credentials --input=$container_backup"
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "✅ Restauração das credenciais concluída com sucesso!"
                } else {
                    Write-Host "❌ Erro ao restaurar credenciais dentro do container."
                }
            } else {
                Write-Host "❌ Erro ao enviar o arquivo de backup para a instância."
            }
        } else {
            Write-Host "❌ Arquivo de backup local não encontrado: $local_backup"
        }
    }

    Pause
}



    default { Write-Host "`n❌ Opção inválida, tente novamente.`n" }
  }

  Write-Host "`n"
  Pause
  Clear-Host
} while ($option -ne "0")
