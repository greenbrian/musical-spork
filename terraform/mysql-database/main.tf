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

  filter {
    name   = "tag:OS-Version"
    values = ["${var.operating_system_version}"]
  }

  filter {
    name   = "tag:Release"
    values = ["${var.image_release}"]
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.ssh_key_name}"
  public_key = "${var.public_key_data}"
}

resource "aws_instance" "db" {
  ami               = "${data.aws_ami.hashistack.id}"
  instance_type     = "t3.small"
  count             = 1
  subnet_id         = "${var.subnet_ids[0]}"
  key_name          = "${var.ssh_key_name}"
  source_dest_check = "false"

  security_groups = [
    "${aws_security_group.allow_all_mysql.id}",
  ]

  associate_public_ip_address = true
  ebs_optimized               = false
  iam_instance_profile        = "${var.instance_profile}"

  tags {
    Name             = "${var.cluster_name} - mysql-database"
    Environment-Name = "${var.environment_name}"
    role             = "database"
    owner            = "${var.owner}"
    TTL              = "${var.ttl}"
  }

  user_data = "${data.template_file.db.rendered}"
}

data "template_file" "db" {
  template = "${file("${path.module}/database.tpl")}"

  vars = {
    environment_name = "${var.environment_name}"
    local_region     = "${var.region}"
    private_key      = "${var.private_key_data}"
    ssh_user_name    = "${var.ssh_user_name}"
  }
}

resource "aws_security_group" "allow_all_mysql" {
  name        = "allow_all_mysql"
  description = "Allow all mysql"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
