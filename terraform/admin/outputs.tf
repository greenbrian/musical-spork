output "ssh_info" {
  value = "${data.template_file.format_ssh.rendered}"
}

output "consul-ui" {
  value = "${var.vanity_domain == "none" ? "http://${aws_instance.admin.public_ip}:8500/ui" : "http://${element(concat(aws_route53_record.consul.*.name, list("")), 0)}:8500/ui"}"
}
