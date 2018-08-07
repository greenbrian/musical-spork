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

variable "remote_regions" {
  type = "list"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "AWS instance type to use eg m4.large"
}

variable "aws_auth_access_key" {
  type        = "string"
  description = "AWS access key used by Vault to validate AWS authentication attempts"
}

variable "aws_auth_secret_key" {
  type        = "string"
  description = "AWS secret key used by Vault to validate AWS authentication attempts"
}

variable "hashistack_instance_arn" {
  description = "AWS IAM role ARN value for Hashistack node"
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

variable "vault_cloud_auto_init_and_unseal" {
  type        = "string"
  description = "Enable or disable automatic Vault initialization and unseal. True or false, string."
}

variable "vault_auto_replication_setup" {
  type        = "string"
  description = "Enable or disable automatic replication configuration between Vault clusters. True or false, string."
}

output "ssh_info" {
  value = "${data.template_file.format_ssh.rendered}"
}

variable "vanity_domain" {
  default     = "none"
  description = "Vanity domain name to use"
}

output "consul-ui" {
  value = "${var.vanity_domain == "none" ? "http://${aws_instance.admin.public_ip}:8500/ui" : "http://${element(concat(aws_route53_record.consul.*.name, list("")), 0)}:8500/ui"}"
}
