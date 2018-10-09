#!/usr/bin/env bash

exec 1> >(logger -s -t $(basename $0)) 2>&1

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
new_hostname="hashistack-nginx-$${public_ipv4}"

echo "${private_key}" > /home/${ssh_user_name}/.ssh/id_rsa
chmod 0700 /home/${ssh_user_name}/.ssh
chmod 0600 /home/${ssh_user_name}/.ssh/id_rsa
chown ${ssh_user_name}:${ssh_user_name} /home/${ssh_user_name}/.ssh/id_rsa

# set the hostname (before starting consul and nomad)
hostnamectl set-hostname "$${new_hostname}"
echo "127.0.0.1 $(hostname)" | sudo tee --append /etc/hosts

cat <<CONSUL-CONFIG>> /etc/consul.d/consul.hcl
datacenter           = "${local_region}"
leave_on_terminate   = true
advertise_addr       = "$${local_ipv4}"
data_dir             = "/opt/consul/data"
client_addr          = "0.0.0.0"
log_level            = "INFO"
ui                   = true
retry_join           = ["provider=aws tag_key=Environment-Name tag_value=${environment_name}"]
disable_remote_exec  = false
enable_script_checks = true
CONSUL-CONFIG
chown consul:consul /etc/consul.d/consul.hcl

cat <<VAULT-AGENT>> /etc/vault-agent.d/vault-agent.hcl
exit_after_auth = true
auto_auth {
  method "aws" {
    mount_path = "auth/aws"
    config     = {
      type     = "iam"
      role     = "aviato"
      }
  }
  sink "file" {
    wrap_ttl = "5m"
    config   = {
      path   = "/mnt/ramdisk/token"
    }
  }
}
VAULT-AGENT

cat <<'NGINX-CONFIG'> /etc/nginx/conf.d/default.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    listen 443 ssl default_server;
    listen [::]:443 ssl  default_server;
    ssl_certificate     /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.crt;

    root /usr/share/nginx/html;
    index index.html secret.html;
    server_name _;
    location / {
      default_type "text/html";
    try_files $uri.html $uri $uri/ /index.html;
    }
}
NGINX-CONFIG

# generate static site
HOST=$(hostname -f)
KERNEL=$(uname -a)
TITLE="System Information for $${HOST}"
RIGHT_NOW=$(date +"%x %r %Z")
TIME_STAMP="Updated on $${RIGHT_NOW} by $${USER}"
AWSPUBHOST=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname)
AWSPUBIP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

cat <<SITE>> /usr/share/nginx/html/index.html
  <html>
  <head>
      <title>$TITLE</title>
      <META HTTP-EQUIV="refresh" CONTENT="5">
  </head>

  <body>
      <h1>$TITLE</h1>
      <p>$TIME_STAMP</p>
      <p>$HOST</p>
      <p>$KERNEL</p>
      <p>AWS public hostname is $AWSPUBHOST</p>
      <p>AWS public IP is $AWSPUBIP</p>
  </body>
  </html>
SITE

cat <<SERVICES>> /etc/consul.d/services.hcl
services = [
  {
    id   = "nginx"
    name = "nginx"
    port = 80
    tags = ["web"]

    checks = [{
      id       = "GET"
      args     = ["curl", "localhost", ">/dev/null", "2>&1"]
      interval = "10s"
    },
    {
      id       = "HTTP-TCP"
      interval = "10s"
      tcp      = "localhost:80"
      timeout  = "1s"
    },
    {
      id       = "OS-Status"
      args     = ["service", "nginx", "status"]
      interval = "30s"
    }
  },
  {
    id   = "nginx-ssl"
    name = "nginx-ssl"
    port = 443
    tags = ["web"]

    checks = [{
      id       = "GET"
      args     = ["curl", "localhost", ">/dev/null", "2>&1"]
      interval = "10s"
    },
    {
      id       = "HTTPS-TCP"
      interval = "10s"
      tcp      = "localhost:443"
      timeout  = "1s"
    },
    {
      id       = "OS-Status"
      args     = ["service", "nginx", "status"]
      interval = "30s"
    }
}]

checks = [
  {
    id       = "report CPU load"
    name     = "CPU Load"
    args     = ["/usr/bin/check_cpu.sh","-w","80","-c","90"]
    interval = "60s"
  },
  {
    id       = "check memory usage"
    name     = "RAM usage"
    args     = ["/usr/bin/check_mem.sh","-w","80","-c","90"]
    interval = "30s"
  },
  {
    id       = "test internet connectivity"
    name     = "ping"
    args     = ["ping", "-c1", "google.com"]
    interval = "30s"
}]
SERVICES


echo "Creating Template for SECRET PAGE..."
cat <<SECRET>> /opt/consul-template/data/secret.html.ctmpl

  <html>
  <head>
      <title>SECRET PAGE</title>
      <META HTTP-EQUIV="refresh" CONTENT="5">
  </head>

{{with secret "aviato/info" }}
  <body>
      <h1>User1 SSN is <i>{{.Data.User1SSN}}</i></h1>
      <h1>User2 SSN is <i>{{.Data.User2SSN}}</i></h1>
      
      <h2>My favorite color is {{key "aviato/color/favorite"}}</h2>
      <h2>Here is a big number: {{key "aviato/number/huge"}}</h2>
  </body>
  </html>
{{end}}
SECRET

echo "Creating Template for private key..."
cat <<CERT>> /opt/consul-template/data/cert.ctmpl
{{ with secret "aviato-intermediate/issue/aviato-dot-com" "common_name=foo.aviato.com" }}
{{ .Data.certificate }}
{{ .Data.private_key }}
{{ end }}
CERT

sudo chmod +x /opt/consul-template/data/*

echo "Install Consul template configuration file for secret page..."
cat <<CT-CONFIG>> /etc/consul-template.d/consul-template.hcl
consul {
  address = "127.0.0.1:8500"

  retry {
    enabled = true
    attempts = 5
    backoff = "250ms"
  }
}

vault {
  address = "http://active.vault.service.consul:8200"

  retry {
    enabled = true
    attempts = 5
    backoff = "250ms"
  }
}

template {
  source = "/opt/consul-template/data/cert.ctmpl"
  destination = "/etc/nginx/ssl/example.com.crt"
  command = "/bin/bash -c 'systemctl restart nginx || true'"
}

template {
  source = "/opt/consul-template/data/secret.html.ctmpl"
  destination = "/usr/share/nginx/html/secret.html"
}
CT-CONFIG

chown root:consul-template /usr/share/nginx/html
chmod 0775 /usr/share/nginx/html/
mkdir -p /etc/nginx/ssl/
chown root:consul-template /etc/nginx/ssl
chmod 0775  /etc/nginx/ssl

systemctl enable consul.service
systemctl start consul
systemctl enable consul-template-vault.service --no-block
systemctl start consul-template-vault