// set the provider to AWS and the AWS region to OREGON
provider "aws" {
  profile    = "test"
  region     = "us-west-2"
  access_key = "AKIAY5S6ZSP2WV7ZU454"
  secret_key = "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"
}
locals {
  my_ip        = ["83.42.17.149/32"]
}
// create the virtual private network
resource "aws_vpc" "dwe-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
 
  tags = {
    Name = "dwe-vpc"
  }
}
// create the internet gateway
resource "aws_internet_gateway" "dwe-igw" {
  vpc_id = "${aws_vpc.dwe-vpc.id}"
 
  tags = {
    Name = "dwe-igw"
  }
}
// create a dedicated subnet
resource "aws_subnet" "dwe-subnet" {
  vpc_id            = "${aws_vpc.dwe-vpc.id}"
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
 
  tags = {
    Name = "dwe-subnet"
  }
}
// create routing table which points to the internet gateway
resource "aws_route_table" "dwe-route" {
  vpc_id = "${aws_vpc.dwe-vpc.id}"
 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.dwe-igw.id}"
  }
 
  tags = {
    Name = "dwe-igw"
  }
}
// associate the routing table with the subnet
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.dwe-subnet.id}"
  route_table_id = "${aws_route_table.dwe-route.id}"
}
// create a security group for ssh access to the linux systems
resource "aws_security_group" "dwe-sg-ssh" {
  name        = "dwe-sg-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = "${aws_vpc.dwe-vpc.id}"
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = local.my_ip
  }
 
  // allow access to the internet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  tags = {
    Name = "dwe-sg-ssh"
  }
}
 
// create a security group for rdp access to the windows systems
resource "aws_security_group" "dwe-sg-rdp" {
name        = "dwe-sg-rdp"
vpc_id      = "${aws_vpc.dwe-vpc.id}"
description = "Allow RDP inbound traffic"
 
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = local.my_ip
  }
 
  // allow access to the internet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
 
  tags = {
    Name = "dwe-sg-rdp"
  }
}
// create two Ubuntu instances
resource "aws_instance" "i-ubuntu-linux-prod" {
  ami                         = "ami-0d1cd67c26f5fca19"
  instance_type               = "t2.micro"
  key_name                    = "IDavinciKeyPair"
  vpc_security_group_ids      = ["${aws_security_group.dwe-sg-ssh.id}"]
  subnet_id                   = "${aws_subnet.dwe-subnet.id}"
  associate_public_ip_address = "true"
 
  root_block_device {
    volume_size           = "10"
    volume_type           = "standard"
    delete_on_termination = "true"
  }
   
  tags = {
    Name = "i-ubuntu-linux-prod"
  }  
}
 
resource "aws_instance" "i-ubuntu-linux-test" {
  ami                         = "ami-0d1cd67c26f5fca19"
  instance_type               = "t2.micro"
  key_name                    = "IDavinciKeyPair"
  vpc_security_group_ids      = ["${aws_security_group.dwe-sg-ssh.id}"]
  subnet_id                   = "${aws_subnet.dwe-subnet.id}"
  associate_public_ip_address = "true"
 
  root_block_device {
    volume_size           = "10"
    volume_type           = "standard"
    delete_on_termination = "true"
  }
 
  tags = {
    Name = "i-ubuntu-linux-test"
  } 
}