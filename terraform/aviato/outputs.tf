output "haproxy_address" {
  value = "ssh://${aws_instance.haproxy.0.public_ip}"
}

output "haproxy_stats" {
  value = "http://${aws_instance.haproxy.0.public_ip}/haproxy?stats"
}

output "haproxy_web_frontend" {
  value = "http://${aws_instance.haproxy.0.public_ip}"
}

output "haproxy_vault_frontend" {
  value = "http://${aws_instance.haproxy.0.public_ip}:8200/ui/"
}

output "haproxy_web_frontend_secrets" {
  value = "http://${aws_instance.haproxy.0.public_ip}/secret.html"
}

output "nginx_addresses" {
  value = "${formatlist("ssh://%s", aws_instance.nginx.*.public_ip)}"
}

output "nginx_cert_check" {
  value = "${formatlist("echo | openssl s_client -showcerts -servername foo.example.com -connect %s:443 2>/dev/null | openssl x509 -inform pem -noout -text | head -n 14", aws_instance.nginx.*.public_ip)}"
}
