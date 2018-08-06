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

output "vault-ui-us-west-2" {
  value = "${module.hashistack-us-west.vault-ui}"
}

output "fabio-ui-us-west-2" {
  value = "${module.hashistack-us-west.fabio-ui}"
}

output "nomad-ui-us-east-1" {
  value = "${module.hashistack-us-east.nomad-ui}"
}

output "fabio-router-haproxy" {
  value = "${module.hashistack-us-east.fabio-router}/haproxy"
}
