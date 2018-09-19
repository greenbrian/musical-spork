#!/usr/bin/env bash

exec 1> >(logger -s -t $(basename $0)) 2>&1

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
new_hostname="hashistack-haproxy-$${public_ipv4}"

echo "${private_key}" > /home/${ssh_user_name}/.ssh/id_rsa
chmod 0700 /home/${ssh_user_name}/.ssh
chmod 0600 /home/${ssh_user_name}/.ssh/id_rsa
chown ${ssh_user_name}:${ssh_user_name} /home/${ssh_user_name}/.ssh/id_rsa

# set the hostname 
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

echo "Consul-template configuration file creation"
cat <<'CT-CONFIG'>> /etc/consul-template.d/haproxy.hcl 
consul = "127.0.0.1:8500"
template {
  source = "/opt/consul-template/data/haproxy.tpl"
  destination = "/etc/haproxy/haproxy.cfg"
  command = "systemctl reload haproxy"
  command = "/bin/sh -c 'haproxy -D -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid)'"
  command_timeout = "30s"
  backup = true
}
CT-CONFIG

echo "Install Consul template template-file for HAProxy..."
cat <<HAPROXY>> /opt/consul-template/data/haproxy.tpl
global
   log /dev/log local0
   log /dev/log local1 notice
   chroot /var/lib/haproxy
   #pidfile     /var/run/haproxy.pid
   stats socket /var/lib/haproxy/stats mode 660 level admin
   stats timeout 30s
   user haproxy
   group haproxy
   daemon

defaults
   log global
   mode http
   option httplog
   option dontlognull
   timeout connect 5000
   timeout client 50000
   timeout server 50000

frontend http_front
   bind *:80
   stats uri /haproxy?stats
   default_backend http_back

backend http_back
   balance roundrobin{{range service "nginx"}}
   server {{.Node}} {{.Address}}:{{.Port}} check{{end}}

frontend https_front
   mode tcp
   bind *:443
   default_backend https_back

backend https_back
   mode tcp
   balance roundrobin{{range service "nginx-ssl"}}
   server {{.Node}} {{.Address}}:{{.Port}} check{{end}}

listen vault
   bind 0.0.0.0:8200
   balance roundrobin
   option httpchk GET /v1/sys/health{{range service "vault"}}
   server {{.Node}} {{.Address}}:{{.Port}} check{{end}}
HAPROXY


cat <<SERVICES>> /etc/consul.d/services.hcl
services = [
  {
    id   = "haproxy"
    name = "haproxy"
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
      args     = ["service", "haproxy", "status"]
      interval = "30s"
    }
  },
  {
    id   = "haproxy-ssl"
    name = "haproxy-ssl"
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
      args     = ["service", "haproxy", "status"]
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

new_hostname=$(curl http://169.254.169.254/latest/meta-data/public-hostname)
hostname $${new_hostname}
bash -c "cat >>/etc/hosts" << HOSTS
127.0.1.1 $new_hostname
HOSTS
bash -c "cat >>/etc/hosts" << NEWHOSTNAME
$${new_hostname}
NEWHOSTNAME

setsebool -P haproxy_connect_any=1
chown root:consul-template /etc/haproxy
chmod 0775 /etc/haproxy


systemctl enable consul.service
systemctl start consul
systemctl enable consul-template.service
systemctl start consul-template
systemctl enable haproxy.service
systemctl start haproxy