variable "environment_name" {}
variable "region" {}
variable "kms_arn" {}

output "policy" {
  value = "${aws_iam_instance_profile.hashistack.id}"
}

output "hashistack_instance_arn" {
  value = "${aws_iam_role.hashistack.arn}"
}