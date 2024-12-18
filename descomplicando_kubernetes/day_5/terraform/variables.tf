variable "private_subnets_us_east" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "ami_id_east_us" {
  description = "AMI ID para as instâncias EC2 us-east-1"
  default     = "ami-0ebfd941bbafe70c6"
}
