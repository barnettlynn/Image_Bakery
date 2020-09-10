provider "aws" {
  region = "us-east-1"
}

# TODO: ACL
# enable dns

terraform {
  backend "s3" {
    bucket = "tfstate-lynnbarnett"
    key    = "prod"
    region = "us-east-1"
  }
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Boiler-VPC"
    App = "Boiler"
  }
}

resource "aws_subnet" "public_A" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_A"
    Type = "public",
    App = "Boiler"
  }
}

resource "aws_subnet" "public_B" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch=true
  tags = {
    Name = "public_B"
    Type = "public"
    App = "Boiler"
  }
}

resource "aws_subnet" "private_A" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "private_A"
    Type = "private"
    App = "Boiler"
  }
}

resource "aws_subnet" "private_B" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"

  tags = {
    Name = "private_B"
    Type = "private"
    App = "Boiler"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Internet Gateway"
    App = "Boiler"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Private_Route_Table_A"
    App = "Boiler"
  }
}

resource "aws_route" "internet_gateway_route" {
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_A.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_B.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat_ip_A" {
    vpc = true
    tags = {
        Name = "NAT_Gateway_A_IP"
        App = "Boiler"
    }
}

resource "aws_eip" "nat_ip_B" {
    vpc = true
    tags = {
        Name = "NAT_Gateway_B_IP"
        App = "Boiler"
    }
}

resource "aws_nat_gateway" "nat_A" {
  allocation_id = aws_eip.nat_ip_A.id
  subnet_id     = aws_subnet.private_A.id

  tags = {
    Name = "NAT_Gateway_A"
    App = "Boiler"
  }
}

resource "aws_nat_gateway" "nat_B" {
  allocation_id = aws_eip.nat_ip_B.id
  subnet_id     = aws_subnet.private_B.id

  tags = {
    Name = "NAT_Gateway_B"
    App = "Boiler"
  }
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Private_Route_Table_A"
    App = "Boiler"
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Private_Route_Table_B"
    App = "Boiler"
  }
}

resource "aws_route" "private_route_B" {
  route_table_id            = aws_route_table.private_a.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_A.id
}

resource "aws_route" "private_route_A" {
  route_table_id            = aws_route_table.private_b.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_B.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id     = aws_subnet.private_A.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id     = aws_subnet.private_A.id
  route_table_id = aws_route_table.private_a.id
}

# export AWS_ACCESS_KEY_ID=AKIAUACF2XUCNQB24HXT
# export AWS_SECRET_ACCESS_KEY=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

resource "aws_eip" "lb_ip" {
    vpc = true
    tags = {
        Name = "LB_IP"
        App = "Boiler"
    }
}

resource "aws_lb" "app_lb" {
    name               = "Books-Load-Balancer"
    load_balancer_type = "application"

    subnets = [aws_subnet.public_A.id, aws_subnet.public_B.id]

    tags = {
        Name = "Books_load_balancer"
        App = "Boiler"
    }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

      ingress {
    description = "TLS from VPC"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

      ingress {
    description = "TLS from VPC"
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

  tags = {
    Name = "Boiler"
  }
}

resource "aws_launch_template" "base_launch_template" {

  name = "books_app_launch_template"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 8
    }
  }

  ebs_optimized = true

  image_id = "ami-06b263d6ceff0b3dd"

  key_name = "lynn2"

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.allow_tls.id]

  user_data = filebase64("./user-data.sh")

  tags = {
        Name = "Books_load_balancer"
        App = "Boiler"
  }
}

resource "aws_autoscaling_group" "bar" {
  name                      = "bakeDemo"
  max_size                  = 5
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 1
  force_delete              = true
  vpc_zone_identifier       = [aws_subnet.public_B.id, aws_subnet.public_A.id]
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.base_launch_template.id
        version = "$Latest"
      }

      override {
        instance_type     = "t3.small"
        weighted_capacity = "3"
      }

      override {
        instance_type     = "t3a.small"
        weighted_capacity = "2"
      }
    }
  }
}