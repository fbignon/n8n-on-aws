Write-Host "🛡️  Removendo Elastic IP do Terraform state (se existir)..."

try {
  ./run-terraform.ps1 state rm aws_eip.n8n_eip
} catch {
  Write-Host "ℹ️  EIP não encontrado no state do Terraform. Pode já ter sido removido."
}

Write-Host "`n🔍 Buscando Allocation ID do Elastic IP com tag 'n8n-instance-eip'..."
$allocationId = aws ec2 describe-addresses `
  --query "Addresses[?Tags[?Key=='Name' && Value=='n8n-instance-eip']].AllocationId" `
  --output text

if (-not $allocationId) {
  Write-Host "⚠️  AllocationId não encontrado. O EIP pode já ter sido liberado ou renomeado."
  exit 0
}

Write-Host "🔓 Liberando Elastic IP: $allocationId"
aws ec2 release-address --allocation-id $allocationId

Write-Host "`n✅ Elastic IP liberado com sucesso.`n"
