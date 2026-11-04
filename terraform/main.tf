data "aws_instance" "existing_server" {
  instance_id = "i-04f9cbed5e41686a3"
}

data "aws_vpc" "existing_vpc" {
  id = "vpc-06ca98d4998ae054e"
}

data "aws_subnet" "existing_subnet" {
  id = "subnet-0c9ea3ae6c6b6b829"
}

data "aws_security_group" "existing_sg" {
  id = "sg-0843c38dc8df09b1b"
}
