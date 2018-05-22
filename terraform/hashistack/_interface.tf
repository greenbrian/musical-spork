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

variable "remote_regions" {
  type = "list"
}

output "vault-ui" {
  value = "http://${aws_lb.vault.dns_name}:8200/ui"
}

output "fabio-ui" {
  value = "http://${aws_lb.fabio.dns_name}:9998"
}
