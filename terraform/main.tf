provider "aws" {
  region = var.aws_region
}

resource "aws_security_group" "n8n_sg" {
  name        = local.security_group_name
  description = "Allow HTTP, SSH, and n8n"

  ingress {
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = local.security_group_name
    },
    local.common_tags
  )
}

resource "aws_instance" "n8n" {
  ami                         = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 (ou Ubuntu, conforme seu caso)
  instance_type               = "t2.micro"
  key_name                    = "n8n-key" # Criada no console AWS
  vpc_security_group_ids      = [aws_security_group.n8n_sg.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/../ec2-user-data.sh")

  tags = merge(
    {
      Name = local.instance_name
    },
    local.common_tags
  )
}
