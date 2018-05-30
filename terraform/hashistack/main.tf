provider "aws" {
  region = "${var.region}"
}

data aws_ami "hashistack" {
  most_recent = true
  owners      = ["self"]
  name_regex  = "hashistack-image-.*"

  filter {
    name   = "tag:OS"
    values = ["${var.operating_system}"]
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.ssh_key_name}"
  public_key = "${var.public_key_data}"
}

data "template_file" "init" {
  template = "${file("${path.module}/init-cluster.tpl")}"

  vars = {
    cluster_size     = "${var.cluster_size}"
    environment_name = "${var.environment_name}"
    wan_join         = "${join(", \n  ", (formatlist("\"provider=aws region=%s tag_key=Environment-Name tag_value=%s\"", var.remote_regions, var.environment_name)))}"
    local_region     = "${var.region}"
    nomad_region     = "${substr(var.region, 0, 7 )}"
    private_key      = "${var.private_key_data}"
    kms_id           = "${var.kms_id}"
    ssh_user_name    = "${var.ssh_user_name}"
  }
}

resource "aws_launch_configuration" "hashistack_server" {
  associate_public_ip_address = false
  ebs_optimized               = false
  iam_instance_profile        = "${var.instance_profile}"
  image_id                    = "${data.aws_ami.hashistack.id}"
  instance_type               = "${var.instance_type}"
  user_data                   = "${data.template_file.init.rendered}"
  key_name                    = "${var.ssh_key_name}"

  security_groups = [
    "${aws_security_group.allow_all_hashistack.id}",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "hashistack_server" {
  launch_configuration = "${aws_launch_configuration.hashistack_server.id}"
  vpc_zone_identifier  = ["${var.subnet_ids}"]
  name                 = "${var.cluster_name} HashiStack Servers"
  max_size             = "${var.cluster_size}"
  min_size             = "${var.cluster_size}"
  desired_capacity     = "${var.cluster_size}"
  default_cooldown     = 30
  force_delete         = true
  health_check_type    = "EC2"
  target_group_arns    = ["${aws_lb_target_group.vault.arn}", "${aws_lb_target_group.fabio-ui.arn}", "${aws_lb_target_group.fabio-http.arn}"]

  tag {
    key                 = "Name"
    value               = "${format("%s HashiStack Server", var.cluster_name)}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Cluster-Name"
    value               = "${var.cluster_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment-Name"
    value               = "${var.environment_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "owner"
    value               = "${var.owner}"
    propagate_at_launch = true
  }

  tag {
    key                 = "TTL"
    value               = "${var.ttl}"
    propagate_at_launch = true
  }
}
