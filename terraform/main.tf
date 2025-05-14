provider "aws" {
  region = var.aws_region
}


resource "aws_s3_bucket" "n8n_data" {
  bucket = "n8n-volume-persistencia"
  force_destroy = true

  tags = merge(
    {
      Name = "n8n-s3-volume"
    },
    local.common_tags
  )
}


resource "aws_iam_role" "n8n_s3_access" {
  name = "n8n-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "n8n_s3_policy" {
  name = "n8n-s3-access"
  role = aws_iam_role.n8n_s3_access.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          "arn:aws:s3:::n8n-volume-persistencia",
          "arn:aws:s3:::n8n-volume-persistencia/*"
        ]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "n8n_instance_profile" {
  name = "n8n-instance-profile"
  role = aws_iam_role.n8n_s3_access.name
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
  iam_instance_profile        = aws_iam_instance_profile.n8n_instance_profile.name

  tags = merge(
    {
      Name = local.instance_name
    },
    local.common_tags
  )
}
