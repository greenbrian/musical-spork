#!/usr/bin/env bash

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
new_hostname="hashistack-$${instance_id}"

# set the hostname (before starting consul and nomad)
hostnamectl set-hostname "$${new_hostname}"

echo "${private_key}" > /home/ubuntu/.ssh/id_rsa
chmod 0700 /home/ubuntu/.ssh
chmod 0600 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa

cat <<EOF>> /etc/consul.d/consul.hcl
datacenter         = "${local_region}"
leave_on_terminate = true
advertise_addr     = "$${local_ipv4}"
data_dir           = "/opt/consul/data"
client_addr        = "0.0.0.0"
log_level          = "INFO"
ui                 = true
retry_join         = ["provider=aws tag_key=Environment-Name tag_value=${environment_name}"]
EOF

chown consul:consul /etc/consul.d/consul.hcl
systemctl start consul

cat << EOF > /etc/systemd/system/consul-template.service
[Unit]
Description=consul-template agent
Requires=network-online.target
After=network-online.target consul.service
[Service]
Restart=on-failure
ExecStart=/usr/local/bin/consul-template -config=/etc/consul-template.d/consul-template.json
KillSignal=SIGINT
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
# Ensure consul cluster elects a leader
while [ "x$${consul_leader_http_code}" != "x200" ] ; do
        echo "Waiting for Consul to get a leader..."
        sleep 5
        consul_leader_http_code=$(curl --silent --output /dev/null --write-out "%{http_code}" "http://127.0.0.1:8500/v1/operator/raft/configuration") || consul_leader_http_code=""
done
sleep 10

# consul read/write functions
cget() { curl -sf http://127.0.0.1:8500/v1/kv/service/vault/$1?raw; }
cput() { curl -sfX PUT --output /dev/null http://127.0.0.1:8500/v1/kv/service/vault/$1 -d $2; }
for region in ${local_region}; do
  # init Vault
  VAULT_HOST=$(curl -s http://127.0.0.1:8500/v1/catalog/service/vault?dc=$${region} | jq -r '.[0].Address')
  curl \
      --silent \
      --request PUT \
      --data '{"recovery_shares": 1, "recovery_threshold": 1}' \
      http://$${VAULT_HOST}:8200/v1/sys/init | tee \
      >(jq -r .root_token > /tmp/$${region}-root-token) \
      >(jq -r .recovery_keys[0] > /tmp/$${region}-unseal-key)
 
  # store region specific root tokens in local Consul cluster
  cput $${region}-root-token $(cat /tmp/$${region}-root-token)
  cput $${region}-unseal-key $(cat /tmp/$${region}-unseal-key)
done
# Set NOMAD_ADDR to connect to local Nomad cluster
sudo cat << EOF > /etc/profile.d/nomad.sh
export NOMAD_ADDR="http://$(curl -s http://127.0.0.1:8500/v1/catalog/service/nomad-server?dc=${local_region} | jq -r '.[0].Address'):4646"
EOF
sleep 10

# Setup Vault demo secret
export VAULT_ADDR="http://active.vault.service.consul:8200"
export VAULT_TOKEN=$(cat /tmp/${local_region}-root-token)
echo '
path "*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}' | vault policy write vault-admin -
vault auth enable userpass
vault write auth/userpass/users/vault password=vault policies=vault-admin
#Run fabio
export NOMAD_ADDR="http://$(curl -s http://127.0.0.1:8500/v1/catalog/service/nomad-server?dc=${local_region} | jq -r '.[0].Address'):4646"
nomad run /home/ubuntu/nomad/fabio-${local_region}.nomad