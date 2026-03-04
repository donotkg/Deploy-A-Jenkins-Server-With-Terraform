terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" 
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg_2026"
  description = "Allow SSH and Jenkins traffic"
  vpc_id      = data.aws_vpc.default.id

  
  ingress {
    description = "Allow SSH Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "Allow 8080 Traffic"
    from_port   = 8080
    to_port     = 8080
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

resource "aws_instance" "jenkins_server" {
  ami           = "ami-0f3caa1cf4417e51b"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              sudo yum upgrade -y
              sudo dnf install java-17-amazon-corretto -y
              sudo yum install jenkins -y
              sudo systemctl enable jenkins
              sudo systemctl start jenkins
              EOF

  tags = {
    Name = "Jenkins-Server"
  }
}

resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket = "jenkins-artifacts-unique-project"
}

resource "aws_s3_bucket_public_access_block" "jenkins_s3_lock" {
  bucket = aws_s3_bucket.jenkins_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

