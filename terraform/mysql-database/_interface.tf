variable "ssh_key_name" {}
variable "public_key_data" {}
variable "private_key_data" {}
variable "vpc_id" {}
variable "environment_name" {}
variable "cluster_name" {}
variable "region" {}
variable "instance_profile" {}
variable "owner" {}
variable "ttl" {}

variable "subnet_ids" {
  type = "list"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS instance type to use eg m4.large"
}

variable "operating_system" {
  default     = "rhel"
  description = "Operating system type, supported options are rhel and ubuntu"
}

variable "operating_system_version" {
  default     = "7.3"
  description = "Operating system version, supported options are 7.3 for rhel, 16.04 for ubuntu"
}

variable "ssh_user_name" {
  default     = "ec2-user"
  description = "Default ssh username for provisioning, ec2-user for rhel systems, ubuntu for ubuntu systems"
}

output "db_address" {
  value = "${aws_instance.db.public_ip}"
}