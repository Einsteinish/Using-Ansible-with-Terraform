variable "aws_region" {
    default = "us-east-1"
}
variable "instance_type" {
    default = "t2.micro"
}
variable "instance_name" {
    default = "terra-ansible"
}
variable "ami_id" {
    default = "ami-0c6b1d09930fac512"
}
variable "ssh_user_name" {
    default = "ec2-user"
}
variable "ssh_key_name" {
    default = "khong-aol"
}
variable "ssh_key_path" {
    default = "~/.ssh/khong-aol.pem"
}
variable "instance_count" {
    default = 1
}
variable "subnet_id" {
    default = "subnet-e03d78ce"
}
variable "dev_host_label" {
    default = "terra_ansible_host"
}
