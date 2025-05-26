output "n8n_url" {
  value = "http://${aws_instance.n8n.public_ip}:5678"
}

output "n8n_elastic_ip" {
  description = "Elastic IP público associado ao n8n. Configure seu DNS para apontar este IP para n8n.globalstorebr.com"
  value       = aws_eip.n8n_eip.public_ip
}

output "n8n_elastic_ip_warning" {
  value = "⚠️ Atenção: O Elastic IP NÃO será destruído automaticamente. Se você não for mais usar, libere manualmente na AWS para evitar cobranças."
  description = "Aviso sobre cobrança do Elastic IP desassociado"
}
