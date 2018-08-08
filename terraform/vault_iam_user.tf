resource "aws_iam_user" "vault_validation" {
  name = "${random_id.environment_name.hex}_vault_validation"
  path = "/${random_id.environment_name.hex}-east/"
}

resource "aws_iam_access_key" "vault" {
  user = "${aws_iam_user.vault_validation.name}"
}

resource "aws_iam_user_policy" "vault_ro" {
  name = "${random_id.environment_name.hex}_vault_validation_policy"
  user = "${aws_iam_user.vault_validation.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "iam:GetRole",
        "iam:GetUser",
        "iam:AttachUserPolicy",
        "iam:CreateAccessKey",
        "iam:CreateUser",
        "iam:DeleteAccessKey",
        "iam:DeleteUser",
        "iam:DeleteUserPolicy",
        "iam:DetachUserPolicy",
        "iam:ListAccessKeys",
        "iam:ListAttachedUserPolicies",
        "iam:ListGroupsForUser",
        "iam:ListUserPolicies",
        "iam:PutUserPolicy",
        "iam:RemoveUserFromGroup"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}