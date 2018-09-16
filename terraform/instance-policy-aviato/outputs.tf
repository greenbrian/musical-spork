output "policy" {
  value = "${aws_iam_instance_profile.aviato.id}"
}

output "aviato_instance_arn" {
  value = "${aws_iam_role.aviato.arn}"
}