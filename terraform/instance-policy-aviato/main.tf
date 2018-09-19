provider "aws" {
  region = "${var.region}"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "aviato" {
  statement {
    sid       = "AllowSelfAssembly"
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInstanceAttribute",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInstances",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs",
      "ec2:DescribeTags",
      "iam:GetInstanceProfile",
      "iam:GetUser",
      "iam:GetRole",
    ]
  }
}

resource "aws_iam_role" "aviato" {
  name               = "aviato-${var.environment_name}"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role.json}"
}

resource "aws_iam_role_policy" "aviato" {
  name   = "aviato-${var.environment_name}-SelfAssembly"
  role   = "${aws_iam_role.aviato.id}"
  policy = "${data.aws_iam_policy_document.aviato.json}"
}

resource "aws_iam_instance_profile" "aviato" {
  name = "aviato-${var.environment_name}"
  role = "${aws_iam_role.aviato.name}"
}
