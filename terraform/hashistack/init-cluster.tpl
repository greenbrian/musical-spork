#!/usr/bin/env bash

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
new_hostname="hashistack-$${instance_id}"

# set the hostname (before starting consul and nomad)
hostnamectl set-hostname "$${new_hostname}"
echo "127.0.0.1 $(hostname)" | sudo tee --append /etc/hosts

echo "${private_key}" > /home/ubuntu/.ssh/id_rsa
chmod 0700 /home/ubuntu/.ssh
chmod 0600 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa

cat << EOF > /etc/vault.d/vault.hcl
storage "consul" {
  address = "127.0.0.1:8500"
  path    = "vault"
}
listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = 1
}
seal "awskms" {
  region     = "us-east-1"
  kms_key_id = "${kms_id}"
}
ui=true
EOF

cat <<EOF>> /etc/consul.d/consul.hcl
datacenter         = "${local_region}"
server             = true
bootstrap_expect   = ${cluster_size}
leave_on_terminate = true
advertise_addr     = "$${local_ipv4}"
data_dir           = "/opt/consul/data"
client_addr        = "0.0.0.0"
log_level          = "INFO"
ui                 = true
retry_join         = ["provider=aws tag_key=Environment-Name tag_value=${environment_name}"]
retry_join_wan     = [ ${wan_join} ]
EOF

chown consul:consul /etc/consul.d/consul.hcl
systemctl start consul

cat <<EOF>> /etc/nomad.d/nomad.hcl
datacenter = \"${local_region}\"
region = \"${nomad_region}\"
data_dir     = "/opt/nomad/data"
log_level    = "INFO"
enable_debug = true

server {
  enabled          = true
  bootstrap_expect = ${cluster_size}
  heartbeat_grace  = "30s"
}

advertise {
  http = \"$${local_ipv4}\"
  rpc  = \"$${local_ipv4}\"
  serf = \"$${local_ipv4}\"
}
consul {
  address        = "127.0.0.1:8500"
  auto_advertise = true

  client_service_name = "nomad-client"
  client_auto_join    = true

  server_service_name = "nomad-server"
  server_auto_join    = true
}

client {
  enabled         = true
  client_max_port = 15000

  options {
    "docker.cleanup.image"   = "0"
    "driver.raw_exec.enable" = "1"
  }
}
EOF

# start nomad once it is configured correctly
systemctl start nomad

# currently no additional configuration required for vault
# todo: support TLS in hashistack and pass in {vault_use_tls} once available
# start vault once it is configured correctly
systemctl start vault

# Setup Nomad-Vault config for Consul Template
echo "Installing Systemd service..."

sudo bash -c "cat >/lib/systemd/system/consul-template.service" << 'EOF'
[Unit]
Description=consul-template agent
Requires=network-online.target
After=network-online.target consul.service
[Service]
EnvironmentFile=-/ramdisk/client_token
Restart=on-failure
ExecStart=/usr/local/bin/consul-template -template "/tmp/nomad-vault.hcl.tpl:/etc/nomad.d/nomad-vault.hcl:service nomad restart"
KillSignal=SIGINT
[Install]
WantedBy=multi-user.target
EOF

sudo chmod 0664 /lib/systemd/system/consul-template.service

# Consul Template file for nomad-vault config
sudo cat << 'EOF' > /tmp/nomad-vault.hcl.tpl
vault {
  enabled = true
  address = "http://active.vault.service.consul:8200"
  token = "{{ key "service/vault/${local_region}-root-token@us-east-1" }}"
}
EOF

sudo systemctl enable consul-template.service
sudo systemctl start consul-template.service