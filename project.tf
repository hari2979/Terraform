terraform {
  required_providers {
    aws = {
        source = "aws"
    }
  }
}
provider "aws"{
    region = "us-east-1"
}
resource "aws_vpc" "myfirst-vpc" {
  cidr_block = "10.0.0.0/16"
  tags ={
    Name = "production"
  }
}
resource "aws_subnet" "prod_subnet" {
  vpc_id = aws_vpc.myfirst-vpc.id
  cidr_block = "10.0.1.0/24"
  tags = {
    Name = "production-subnet"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myfirst-vpc.id
  tags = {
    Name = "Internet-gateway"
  }
}
resource "aws_route_table" "publicRT" {
  vpc_id = aws_vpc.myfirst-vpc.id
  route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Route-Table1"
  }
}
resource "aws_route_table_association" "routetableassociation" {
  subnet_id = aws_subnet.prod_subnet.id
  route_table_id = aws_route_table.publicRT.id
}
resource "aws_security_group" "allow_web" {
  name        = "Web application"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.myfirst-vpc.id

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
    Name = "allow_web"
  }
}
resource "aws_network_interface" "mission" {
  subnet_id       = aws_subnet.prod_subnet.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}
resource "aws_eip" "only_one" {
  network_interface = aws_network_interface.mission.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [ aws_internet_gateway.igw ]
}
resource "aws_instance" "projectmission" {
  ami = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  key_name = "Docker"

  network_interface{
    device_index = 0
    network_interface_id = aws_network_interface.mission.id
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo bash -c 'echo welcome Hari Krishnan Janarthanan > /var/www/html/index.html'
                EOF

}
