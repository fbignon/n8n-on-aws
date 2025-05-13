param (
    [string]$Command = "plan"
)

Write-Host "Executando comando: terraform $Command"

# Detectar se está no PowerShell (Windows)
$projectPath = $PWD.Path
$awsPath = "$env:USERPROFILE\.aws"

Write-Host "Montando volume do projeto: $projectPath"
Write-Host "Montando credenciais AWS: $awsPath"

docker run --rm -it `
  -v "${projectPath}:/workspace" `
  -v "${awsPath}:/root/.aws:ro" `
  terraform-n8n $Command
