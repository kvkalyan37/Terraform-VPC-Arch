variable "awsprops" {
    type = "map"
    default = {
    region = "ap-south-1"
    access_key = ""
    secret_key = ""
    main_vpc_cidr = "10.0.0.0/16"
    public_subnets = "10.0.1.0/24"
    private_subnets = "10.0.2.0/24"
    ami = "ami-0a9d27a9f4f5c0efc"
    instance_type = "t2.micro"
    publicip = true
    key_name = "kvk_pem" #AWS Pem File
  }
}