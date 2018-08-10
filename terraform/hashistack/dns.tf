data "aws_route53_zone" "selected" {
  count = "${var.vanity_domain == "none" ? 0 : 1}"
  name  = "${var.vanity_domain}."
}

resource "random_id" "post_num" {
  byte_length = 1
}

resource "aws_route53_record" "vault" {
  count   = "${var.vanity_domain == "none" ? 0 : 1}"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "vault-${random_id.post_num.dec}.${var.vanity_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_lb.vault.dns_name}"]
}

resource "aws_route53_record" "fabio" {
  count   = "${var.vanity_domain == "none" ? 0 : 1}"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "fabio-${random_id.post_num.dec}.${var.vanity_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_lb.fabio.dns_name}"]
}

resource "aws_route53_record" "nomad" {
  count   = "${var.vanity_domain == "none" ? 0 : 1}"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "nomad-${random_id.post_num.dec}.${var.vanity_domain}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_lb.nomad.dns_name}"]
}
