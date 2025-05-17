locals {
  project_prefix        = "n8n-instance"
  timestamp             = formatdate("YYYY-MM-DD_HH-mm-ss", timestamp())

  instance_name         = "${local.project_prefix}_${replace(local.timestamp, ":", "-")}"
  security_group_name   = "${local.project_prefix}-sg"
  volume_name           = "${local.project_prefix}-volume"

  common_tags = {
    Project    = local.project_prefix
    Environment = "production"
    Owner       = "automated"
  }
}
