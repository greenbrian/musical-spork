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

output "ssh_info" {
  value = "${data.template_file.format_ssh.rendered}"
}

output "consul-ui" {
  value = "http://${aws_instance.admin.public_ip}:8500/ui"
}
