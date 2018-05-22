# Optional Variables
variable "private_key_filename" {
  default     = "private_key.pem"
  description = "Filename to write the private key data to eg key.pem"
}

# Required variables
variable "ssh_key_name" {
  description = "AWS key pair name that will be created"
}

# Outputs
output "private_key_data" {
  value = "${tls_private_key.main.private_key_pem}"
}

output "ssh_key_name" {
  value = "${aws_key_pair.main.key_name}"
}

output "public_key_data" {
  value = "${tls_private_key.main.public_key_openssh}"
}
