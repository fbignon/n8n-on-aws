output "n8n_url" {
  value = "http://${aws_instance.n8n.public_ip}:5678"
}

output "n8n_elastic_ip" {
  value = aws_eip.n8n_eip.public_ip
  description = "Elastic IP público associado ao n8n"
}
