variable "ssh_key_name" {}
variable "public_key_data" {}
variable "private_key_data" {}
variable "vpc_id" {}
variable "environment_name" {}
variable "cluster_name" {}
variable "region" {}
variable "instance_profile" {}
variable "kms_id" {}
variable "owner" {}
variable "ttl" {}

variable "subnet_ids" {
  type = "list"
}

variable "public_subnet_ids" {
  type = "list"
}

variable "cluster_size" {
  default     = "3"
  description = "Number of instances to launch in the cluster"
}

variable "instance_type" {
  default     = "t2.large"
  description = "AWS instance type to use"
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

variable "remote_regions" {
  type = "list"
}

output "vault-ui" {
  value = "http://${aws_lb.vault.dns_name}:8200/ui"
}

output "fabio-ui" {
  value = "http://${aws_lb.fabio.dns_name}:9998"
}

output "fabio-router" {
  value = "http://${aws_lb.fabio.dns_name}:9999"
}