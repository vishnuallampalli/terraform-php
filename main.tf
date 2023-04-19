terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.72.0"
    }
  }
}

locals {
  vpc_id           = "vpc-01bd8dfbca63589e0"
  subnet_id        = "subnet-0fff856dcab65951c"
  ssh_user         = "ec2-user"
  key_name         = "password"
  private_key_path = "/home/ec2-user/new-key.pem"
}

provider "aws" {
  region = "ap-south-1"
  shared_credentials_files = "/home/ec2-user/.aws/credentials"
}

resource "aws_security_group" "httpd" {
  name   = "httpd_access"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_instance" "httpd" {
  ami                         = "ami-07d3a50bd29811cd1"
  subnet_id                   = "subnet-0fff856dcab65951c"
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.httpd.id]
  key_name                    = local.key_name

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = aws_instance.httpd.public_ip
    }
  }
  provisioner "local-exec" {
    command = "ansible-playbook  -i ${aws_instance.httpd.public_ip}, --private-key ${local.private_key_path} nginx.yaml"
  }
}

output "httpd_ip" {
  value = aws_instance.httpd.public_ip
}
