provider "aws" {
  region = "us-east-1"
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "latest_amazon_linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
}

resource "aws_instance" "my_amazon" {
  ami                         = data.aws_ami.latest_amazon_linux.id
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.sohel_key.key_name
  subnet_id                   = aws_subnet.public_subnet.id
  security_groups             = [aws_security_group.host_sg.id]
  associate_public_ip_address = true
  # provisioner "file" {
  #   source     = "kind.yaml"
  #   destination = "/home/ec2-user/kind.yaml"
  #   connection {
  #   type     = "ssh"
  #   user     = "root"
  #   host = self.public_ip
  #   host_key = file("/home/ec2-user/.ssh/sohel_key.pub")
  # }
  # } -->> Not working, shows ssh authentication failed, handhsake failed, key mismatch
  user_data = file("docker.sh")
  //iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name  -> Access to iam roles not allowed

  tags = {
    "Name" = "Linux K8s Host"
  }

}

resource "aws_security_group" "host_sg" {
  name        = "Host-SG"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.vpc.id


  ingress {
    description      = "SSH from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description      = "http from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "dockerhost-sg"
  }
}

resource "aws_key_pair" "sohel_key" {
  key_name   = "sohel_key"
  public_key = file("/home/ec2-user/.ssh/sohel_key.pub")
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name" = "Host-IGW"
  }
}

resource "aws_route_table" "host_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = "Host-RT"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.host_rt.id
}

resource "aws_ecr_repository" "ecr_repo" {
  name                 = "docker_ecr"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

output "public_ip"{
  value = aws_instance.my_amazon.public_ip
}