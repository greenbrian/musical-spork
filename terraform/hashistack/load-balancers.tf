#Vault
resource "aws_lb" "vault" {
  name               = "${var.environment_name}-vault"
  load_balancer_type = "application"
  internal           = false
  subnets            = ["${var.public_subnet_ids}"]
  security_groups    = ["${aws_security_group.allow_all_hashistack.id}"]
}

resource "aws_lb_target_group" "vault" {
  port     = 8200
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"

  health_check {
    path = "/v1/sys/health"
  }
}

resource "aws_lb_listener" "vault" {
  load_balancer_arn = "${aws_lb.vault.arn}"
  port              = "8200"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.vault.arn}"
    type             = "forward"
  }
}

#Fabio
resource "aws_lb" "fabio" {
  name               = "${var.environment_name}-fabio"
  load_balancer_type = "network"
  internal           = false
  subnets            = ["${var.public_subnet_ids}"]
}

resource "aws_lb_target_group" "fabio-ui" {
  port     = 9998
  protocol = "TCP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_target_group" "fabio-http" {
  port     = 9999
  protocol = "TCP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_listener" "fabio-ui" {
  load_balancer_arn = "${aws_lb.fabio.arn}"
  port              = "9998"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.fabio-ui.arn}"
    type             = "forward"
  }
}

resource "aws_lb_listener" "fabio-http" {
  load_balancer_arn = "${aws_lb.fabio.arn}"
  port              = "9999"
  protocol          = "TCP"

  default_action {
    target_group_arn = "${aws_lb_target_group.fabio-http.arn}"
    type             = "forward"
  }
}

resource "aws_lb" "nomad" {
  name               = "${var.environment_name}-nomad"
  load_balancer_type = "application"
  internal           = false
  subnets            = ["${var.public_subnet_ids}"]
  security_groups    = ["${aws_security_group.allow_all_hashistack.id}"]
}

resource "aws_lb_target_group" "nomad" {
  port     = 4646
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_listener" "nomad" {
  load_balancer_arn = "${aws_lb.nomad.arn}"
  port              = "4646"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.nomad.arn}"
    type             = "forward"
  }
}

resource "aws_autoscaling_attachment" "asg_attachment_nomad" {
  autoscaling_group_name = "${aws_autoscaling_group.hashistack_server.id}"
  alb_target_group_arn   = "${aws_lb_target_group.nomad.arn}"
}
