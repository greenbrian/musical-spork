resource "tls_private_key" "main" {
  algorithm = "RSA"
}

resource "null_resource" "main" {
  provisioner "local-exec" {
    command = "echo \"${tls_private_key.main.private_key_pem}\" > ${var.private_key_filename}"
  }

  provisioner "local-exec" {
    command = "chmod 600 ${var.private_key_filename}"
  }
}

resource "aws_key_pair" "main" {
  key_name   = "${var.ssh_key_name}"
  public_key = "${tls_private_key.main.public_key_openssh}"
}
