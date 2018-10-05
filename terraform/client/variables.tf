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

variable "hashistack_instance_arn" {
  description = "AWS IAM role ARN value for Hashistack node"
}

variable "operating_system" {
  default     = "centos"
  description = "Operating system type, supported options are rhel, centos, and ubuntu"
}

variable "operating_system_version" {
  default     = "7"
  description = "Operating system version, supported options are 7.5 for rhel, 7 for CentOS, 16.04/18.04 for ubuntu"
}

variable "ssh_user_name" {
  default     = "centos"
  description = "Default ssh username for provisioning, ec2-user for rhel systems, ubuntu for ubuntu systems"
}

output "ssh_info" {
  value = "${data.template_file.format_ssh.rendered}"
}

variable "vanity_domain" {
  default     = "none"
  description = "Vanity domain name to use"
}
