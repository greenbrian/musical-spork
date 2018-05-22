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
