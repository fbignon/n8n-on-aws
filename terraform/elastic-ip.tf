resource "aws_eip" "n8n_eip" {
  vpc = true

  tags = merge(
    {
      Name = "${local.project_prefix}-eip"
    },
    local.common_tags
  )
}
