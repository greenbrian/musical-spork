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
