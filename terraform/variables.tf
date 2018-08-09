variable "owner" {
  description = "User responsible for this cloud environment, resources will be tagged with this"
}

variable "ttl" {
  default     = 72
  description = "Tag indicating time to live for this cloud environment"
}

variable "env_name" {
  description = "Tag indicating environment name"
}

variable "vault_cloud_auto_init_and_unseal" {
  type        = "string"
  description = "Enable or disable automatic Vault initialization and unseal. True or false, string."
}

variable "vault_auto_replication_setup" {
  type        = "string"
  description = "Enable or disable automatic replication configuration between Vault clusters. True or false, string."
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

variable "root_domain" {
  default     = "none"
  description = "Domain to use for vanity demos"
}
