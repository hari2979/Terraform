terraform {
  required_providers {
    aws = {
        source = "aws"
    }
  }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_instance" "Sample_1" {
    ami = "ami-053b0d53c279acc90" # Ubuntu oda AMI Id taken from AWS account
    instance_type = "t2.micro"
    count = 2
    tags = {
      name = "myfirstEC2"
    }
}