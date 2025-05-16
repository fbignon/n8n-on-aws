resource "aws_eip_association" "n8n_assoc" {
  instance_id   = aws_instance.n8n.id
  allocation_id = aws_eip.n8n_eip.id
}
