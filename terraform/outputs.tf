output "admin-ssh-us-east-1" {
  value = "${module.admin-east.ssh_info}"
}

output "consul-ui-us-east-1" {
  value = "${module.admin-east.consul-ui}"
}

output "vault-ui-us-east-1" {
  value = "${module.hashistack-us-east.vault-ui}"
}

output "fabio-ui-us-east-1" {
  value = "${module.hashistack-us-east.fabio-ui}"
}

output "admin-ssh-us-west-1" {
  value = "${module.admin-west.ssh_info}"
}

output "consul-ui-us-west-1" {
  value = "${module.admin-west.consul-ui}"
}

output "vault-ui-us-west-1" {
  value = "${module.hashistack-us-west.vault-ui}"
}

output "fabio-ui-us-west-1" {
  value = "${module.hashistack-us-west.fabio-ui}"
}
