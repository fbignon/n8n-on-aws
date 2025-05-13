locals {
  # Data/hora formatada como parte do nome dos recursos
  timestamp_formatted   = formatdate("YYYY-MM-DD_HH-mm-ss", timestamp())

  # Nomes únicos para recursos
  instance_name         = "n8n-instance_${local.timestamp_formatted}"
  security_group_name   = "n8n-sg_${local.timestamp_formatted}"
  volume_name           = "n8n-volume_${local.timestamp_formatted}"

  # Tags padrão aplicadas a todos os recursos
  common_tags = {
    Environment = "production"
    Owner       = "automated"
  }
}
