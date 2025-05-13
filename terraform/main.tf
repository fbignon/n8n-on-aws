provider "aws" {
  region = var.aws_region
}

resource "aws_key_pair" "deployer" {
  key_name   = "n8n-key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "n8n_sg" {
  name        = "n8n-sg"
  description = "Allow HTTP and n8n"
  ingress {
    from_port   = 5678
    to_port     = 5678
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "n8n" {
  ami                         = "ami-096af71d77183c8f8" # Amazon Linux 2 (região us-east-2)
  instance_type               = "t2.micro"
  key_name                    = aws_key_pair.deployer.key_name
  vpc_security_group_ids      = [aws_security_group.n8n_sg.id]
  associate_public_ip_address = true
  user_data                   = file("${path.module}/../ec2-user-data.sh")

  tags = {
    Name = "n8n-aws-instance"
  }
}
