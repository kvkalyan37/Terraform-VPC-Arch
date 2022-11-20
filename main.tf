provider "aws" {
  region = lookup(var.awsprops, "region")
  access_key = lookup(var.awsprops, "access_key")
  secret_key = lookup(var.awsprops, "secret_key")
}


# Create the VPC
 resource "aws_vpc" "Main" {                # Creating VPC here
   cidr_block       = lookup(var.awsprops, "main_vpc_cidr")    # Defining the CIDR block use 10.0.0.0/24 for demo
   instance_tenancy = "default"
 }

  #  Create Internet Gateway and attach it to VPC
 resource "aws_internet_gateway" "IGW" {    # Creating Internet Gateway
    vpc_id =  aws_vpc.Main.id               # vpc_id will be generated after we create VPC
 }

#  Create a Public Subnets.
 resource "aws_subnet" "publicsubnets" {    # Creating Public Subnets
   vpc_id =  aws_vpc.Main.id
   cidr_block = lookup(var.awsprops, "public_subnets")      # CIDR block of public subnets
 }
#  Create a Private Subnet                   # Creating Private Subnets
 resource "aws_subnet" "privatesubnets" {
   vpc_id =  aws_vpc.Main.id
   cidr_block = lookup(var.awsprops, "private_subnets")         # CIDR block of private subnets
 }

#  Route table for Public Subnet's
 resource "aws_route_table" "PublicRT" {    # Creating RT for Public Subnet
    vpc_id =  aws_vpc.Main.id
         route {
    cidr_block = "0.0.0.0/0"               # Traffic from Public Subnet reaches Internet via Internet Gateway
    gateway_id = aws_internet_gateway.IGW.id
     }
 }
#  Route table for Private Subnet's
 resource "aws_route_table" "PrivateRT" {    # Creating RT for Private Subnet
   vpc_id = aws_vpc.Main.id
   route {
   cidr_block = "0.0.0.0/0"             # Traffic from Private Subnet reaches Internet via NAT Gateway
   nat_gateway_id = aws_nat_gateway.NATgw.id
   }
 }
#  Route table Association with Public Subnet's
 resource "aws_route_table_association" "PublicRTassociation" {
    subnet_id = aws_subnet.publicsubnets.id
    route_table_id = aws_route_table.PublicRT.id
 }
#  Route table Association with Private Subnet's
 resource "aws_route_table_association" "PrivateRTassociation" {
    subnet_id = aws_subnet.privatesubnets.id
    route_table_id = aws_route_table.PrivateRT.id
 }
 resource "aws_eip" "nateIP" {
   vpc   = true
 }
#  Creating the NAT Gateway using subnet_id and allocation_id
 resource "aws_nat_gateway" "NATgw" {
   allocation_id = aws_eip.nateIP.id
   subnet_id = aws_subnet.publicsubnets.id
 }



# Configure the AWS Public EC2 Instance
resource "aws_instance" "AWS_EC2" {
    ami = lookup(var.awsprops, "ami")
    instance_type = lookup(var.awsprops, "instance_type")
    user_data = "${file("UserData.sh")}"
    security_groups = [ "KVK_SG" ]
    key_name = lookup(var.awsprops, "key_name") #Key Pair Name
    subnet_id = aws_subnet.publicsubnets.id
    tags = {
      Name = "RHEL-Public-EC2-Instance" #EC2-Name
    }
}

# Configure the AWS Private EC2 Instance
resource "aws_instance" "AWS_EC2" {
    ami = lookup(var.awsprops, "ami")
    instance_type = lookup(var.awsprops, "instance_type")
    user_data = "${file("UserData.sh")}"
    security_groups = [ "KVK_SG" ]
    key_name = lookup(var.awsprops, "key_name") #Key Pair Name
    subnet_id = aws_subnet.privatesubnets.id
    tags = {
      Name = "RHEL-Private-EC2-Instance" #EC2-Name
    }
}

# Configure the AWS SG
resource "aws_security_group" "AWS_SG" {
    name = "KVK_SG" #Group Name
    description = "Security Group by Terraform"
    vpc_id = aws_vpc.Main.id
    #inbound rules
    ingress{
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }
    #outbound rules
    egress{
      from_port = 443
      to_port = 443
      protocol = "tcp"
      cidr_blocks = [ "0.0.0.0/0" ]
    }
    tags = {
      Name = "KVK-SG-by-TF" #SG-Name
    }
}