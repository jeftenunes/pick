terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.69"
    }
  }
}

resource "aws_iam_role" "ssm_role" {
  name = "ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_policy_attach" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm-instance-profile"
  role = aws_iam_role.ssm_role.name
}

resource "aws_vpc" "vpc_us_east" {
  enable_dns_support   = true
  enable_dns_hostnames = true
  provider             = aws.us_east
  cidr_block           = "10.0.0.0/16"
}

resource "aws_subnet" "private_subnet_us_east" {
  provider          = aws.us_east
  count             = length(var.private_subnets_us_east)
  vpc_id            = aws_vpc.vpc_us_east.id
  cidr_block        = element(var.private_subnets_us_east, count.index)
  availability_zone = "us-east-1a"

  tags = {
    Name = "private_subnets_us_east_${count.index}"
  }
}

resource "aws_subnet" "public_subnet" {
  provider                = aws.us_east
  vpc_id                  = aws_vpc.vpc_us_east.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_security_group" "allow_internal_traffic" {
  provider = aws.us_east
  vpc_id   = aws_vpc.vpc_us_east.id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
    description      = "Allow traffic on all ports and ip ranges"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  provider = aws.us_east
  vpc_id   = aws_vpc.vpc_us_east.id

  tags = {
    Name = "internet_gateway"
  }
}

resource "aws_route_table" "public_rt" {
  provider = aws.us_east
  vpc_id   = aws_vpc.vpc_us_east.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  provider       = aws.us_east
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_instance" "control_plane" {
  provider                    = aws.us_east
  instance_type               = "t3.medium"
  ami                         = var.ami_id_east_us
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.allow_internal_traffic.id]
  associate_public_ip_address = true

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash

              if ! command -v amazon-ssm-agent &> /dev/null; then
                  echo "Instalando o SSM Agent..."
                  sudo snap install amazon-ssm-agent --classic
              fi

              sudo systemctl start amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent

              EOF
}

resource "aws_instance" "worker1" {
  provider               = aws.us_east
  instance_type          = "t3.medium"
  ami                    = var.ami_id_east_us
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_internal_traffic.id]

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash

              if ! command -v amazon-ssm-agent &> /dev/null; then
                  echo "Instalando o SSM Agent..."
                  sudo snap install amazon-ssm-agent --classic
              fi

              sudo systemctl start amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent

              EOF
}

resource "aws_instance" "worker2" {
  provider               = aws.us_east
  instance_type          = "t3.medium"
  ami                    = var.ami_id_east_us
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.allow_internal_traffic.id]

  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash

              if ! command -v amazon-ssm-agent &> /dev/null; then
                  echo "Instalando o SSM Agent..."
                  sudo snap install amazon-ssm-agent --classic
              fi

              sudo systemctl start amazon-ssm-agent
              sudo systemctl enable amazon-ssm-agent

              EOF
}
