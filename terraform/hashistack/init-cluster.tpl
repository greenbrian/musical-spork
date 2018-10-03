#!/usr/bin/env bash

exec 1> >(logger -s -t $(basename $0)) 2>&1

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
availability_zone="$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
new_hostname="hashistack-cluster-$${local_ipv4}"

echo "${private_key}" > /home/${ssh_user_name}/.ssh/id_rsa
chmod 0700 /home/${ssh_user_name}/.ssh
chmod 0600 /home/${ssh_user_name}/.ssh/id_rsa
chown ${ssh_user_name}:${ssh_user_name} /home/${ssh_user_name}/.ssh/id_rsa

# set the hostname (before starting consul and nomad)
hostnamectl set-hostname "$${new_hostname}"
echo "127.0.0.1 $(hostname)" | sudo tee --append /etc/hosts

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
datacenter          = "${local_region}"
server              = true
bootstrap_expect    = ${cluster_size}
leave_on_terminate  = true
advertise_addr      = "$${local_ipv4}"
data_dir            = "/opt/consul/data"
client_addr         = "0.0.0.0"
log_level           = "INFO"
ui                  = true
retry_join          = ["provider=aws tag_key=Environment-Name tag_value=${environment_name}"]
retry_join_wan      = [ ${wan_join} ]
disable_remote_exec = false
connect {
  enabled = true
}
acl_datacenter = "us-east-1"
acl_master_token = "mybigsecret"
acl_default_policy = "allow"
acl_down_policy = "extend-cache"
EOF

chown consul:consul /etc/consul.d/consul.hcl
systemctl start consul

cat <<EOF>> /etc/nomad.d/nomad.hcl
datacenter = "$${availability_zone}"
region = "${local_region}"
data_dir     = "/opt/nomad/data"
log_level    = "INFO"
enable_debug = true

server {
  enabled          = true
  bootstrap_expect = ${cluster_size}
  heartbeat_grace  = "30s"
}

advertise {
  http = "$${local_ipv4}"
  rpc  = "$${local_ipv4}"
  serf = "$${local_ipv4}"
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
	
vault {	
  enabled = true	
  address = "http://active.vault.service.consul:8200"
  create_from_role = "nomad-cluster"
}	
EOF

cat <<VAULT-AGENT>> /etc/vault-agent.d/vault-agent.hcl
pid_file = "/var/run.vault-agent.pid"
auto_auth {
  method "aws" {
    mount_path = "auth/aws"
    config     = {
      type     = "iam"
      role     = "nomad"
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


# start nomad once it is configured correctly
systemctl start nomad.service --no-block

# start vault agent secure intro
systemctl start vault-agent.service --no-block

# currently no additional configuration required for vault
# todo: support TLS in hashistack and pass in {vault_use_tls} once available
# start vault once it is configured correctly
systemctl start vault
