param (
    [string]$Mensagem = "Atualizações no projeto"
)

Write-Output "Verificando modificações no repositório..."
git status

Write-Output ""
Write-Output "Adicionando arquivos alterados..."
git add .

Write-Output "Fazendo commit..."
git commit -m "$Mensagem"

Write-Output "Enviando para o GitHub..."
git push origin main

Write-Output ""
Write-Output "Git atualizado com sucesso!"
