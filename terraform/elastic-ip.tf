resource "aws_eip" "n8n_eip" {
  domain = "vpc"

  tags = merge(
    {
      Name = "${local.project_prefix}-eip"
    },
    local.common_tags
  )
    lifecycle {
    prevent_destroy = true
  }
}
