provider "aws" {
  region = "eu-west-2"
  access_key = "**********"
  secret_key = "**********"
}
resource "aws_vpc" "MY-FIRST-VPC" {
  cidr_block = "10.0.0.0/16"
  tags={
    Name= "MY-VPC"
  }
  
}
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.MY-FIRST-VPC.id

  }
  resource "aws_route_table" "myroute" {
  vpc_id =aws_vpc.MY-FIRST-VPC.id 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  
  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "example"
  }
   }  
  resource "aws_subnet" "mysubnet" {
  vpc_id     = aws_vpc.MY-FIRST-VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone= "eu-west-2a"
  tags = {
    Name = "Main"
  }
  }
  resource "aws_route_table_association" "a" {
  subnet_id      =aws_subnet.mysubnet.id
  route_table_id = aws_route_table.myroute.id
}
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "allow_web_traffic"
  vpc_id      = aws_vpc.MY-FIRST-VPC.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
 ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
   ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_webtraffic"
  }
}
resource "aws_network_interface" "MYNIT" {
  subnet_id       = aws_subnet.mysubnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

  }
  
resource "aws_eip" "myeip" {
  vpc                       = true
  network_interface         = aws_network_interface.MYNIT.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_route_table.myroute]
}
resource "aws_instance" "MY-SERVER" {
  ami                     = "ami-0eb260c4d5475b901"
  instance_type           = "t2.micro"
  availability_zone = "eu-west-2a"
  key_name = "kp"

  network_interface {
    device_index = 0
    network_interface_id= aws_network_interface.MYNIT.id
  }
  user_data = <<-EOF
             #!/bin/bash
             sudo apt update -y
             sudo apt install apache-2 -y
             sudo systemctl start apache2
             sudo bash -c 'echo your very first web server > /var/www/html/index.html'
             EOF
tags= {
  Name="web-server"
}
}
