variable "owner" {
  description = "User responsible for this cloud environment, resources will be tagged with this"
}

variable "ttl" {
  default     = 72
  description = "Tag indicating time to live for this cloud environment"
}

variable "image_release" {
  default     = "stable"
  description = "machine metadata (ami tag etc) indicating image version; test, beta, stable etc"
}

variable "env_name" {
  description = "Tag indicating environment name"
}

variable "nginx_count" {
  description = "Nginx server count"
  default     = 2
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

variable "root_domain" {
  default     = "none"
  description = "Domain to use for vanity demos"
}

variable "launch_nomad_jobs_automatically" {
  type        = "string" 
  default     = "true"
  description = "Enable or disable automatic Nomad deployment of Fabio and other demo applications"
}