output "n8n_url" {
  value = "http://${aws_instance.n8n.public_ip}:5678"
}
