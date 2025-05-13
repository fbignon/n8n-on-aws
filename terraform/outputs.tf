output "instance_name" {
  value = local.instance_name
}

output "security_group_name" {
  value = local.security_group_name
}

output "n8n_url" {
  value = "http://${aws_instance.n8n.public_ip}:5678"
}
