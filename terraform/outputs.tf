output "admin-ssh-us-east-1" {
  value = "${module.admin-east.ssh_info}"
}

output "client-ssh-us-west-2" {
  value = "${module.client-west.ssh_info}"
}

output "mysql-database-us-east-1" {
  value = "${module.mysql-database.db_address}"
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

output "nginx_addresses" {
  value = "${module.aviato.nginx_addresses}"
}

output "ngninx_openssl_check" {
  value = "${module.aviato.nginx_cert_check}"
}

output "haproxy_address" {
  value = "${module.aviato.haproxy_address}"
}

output "haproxy_stats" {
  value = "${module.aviato.haproxy_stats}"
}

output "haproxy_web_frontend" {
  value = "${module.aviato.haproxy_web_frontend}"
}

output "haproxy_vault_frontend" {
  value = "${module.aviato.haproxy_vault_frontend}"
}

output "secrets_page" {
  value = "${module.aviato.haproxy_web_frontend_secrets}"
}

output "private_key_data" {
  value = "${module.ssh.private_key_data}"
}

output "ssh_key_name" {
  value = "${module.ssh.ssh_key_name}"
}

output "public_key_data" {
  value = "${module.ssh.public_key_data}"
}
