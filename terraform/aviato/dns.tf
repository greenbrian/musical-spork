data "aws_route53_zone" "selected" {
  count = "${var.vanity_domain == "none" ? 0 : 1}"
  name  = "${var.vanity_domain}."
}

resource "random_id" "post_num" {
  byte_length = 1
}

resource "aws_route53_record" "haproxy" {
  count   = "${var.vanity_domain == "none" ? 0 : 1}"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "haproxy-${random_id.post_num.dec}.${var.vanity_domain}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.haproxy.public_ip}"]
}
