
output "vault-ui" {
  value = "${var.vanity_domain == "none" ? "http://${aws_lb.vault.dns_name}:8200/ui" : "http://${element(concat(aws_route53_record.vault.*.name, list("")), 0)}:8200/ui"}"
}

output "fabio-ui" {
  value = "${var.vanity_domain == "none" ? "http://${aws_lb.fabio.dns_name}:9998" : "http://${element(concat(aws_route53_record.fabio.*.name, list("")), 0)}:9998"}"
}

output "nomad-ui" {
  value = "${var.vanity_domain == "none" ? "http://${aws_lb.nomad.dns_name}:4646/ui" : "http://${element(concat(aws_route53_record.nomad.*.name, list("")), 0)}:4646/ui"}"
}

output "fabio-router" {
  value = "${var.vanity_domain == "none" ? "http://${aws_lb.fabio.dns_name}:9999" : "http://${element(concat(aws_route53_record.fabio.*.name, list("")), 0)}:9999"}"
}
