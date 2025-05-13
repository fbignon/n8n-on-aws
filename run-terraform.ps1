param (
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

Write-Output "Executando comando: terraform $($Args -join ' ')"

$projectPath = $PWD.Path
$awsPath = "$env:USERPROFILE\.aws"

Write-Output "Montando volume do projeto: $projectPath"
Write-Output "Montando credenciais AWS: $awsPath"

docker run --rm -it `
    -v "${projectPath}:/workspace" `
    -v "${awsPath}:/root/.aws:ro" `
    terraform-n8n $Args
