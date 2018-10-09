#!/usr/bin/env bash

exec 1> >(logger -s -t $(basename $0)) 2>&1

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
new_hostname="hashistack-admin"

echo "${private_key}" > /home/${ssh_user_name}/.ssh/id_rsa
chmod 0700 /home/${ssh_user_name}/.ssh
chmod 0600 /home/${ssh_user_name}/.ssh/id_rsa
chown ${ssh_user_name}:${ssh_user_name} /home/${ssh_user_name}/.ssh/id_rsa

# set the hostname (before starting consul and nomad)
hostnamectl set-hostname "$${new_hostname}"
echo "127.0.0.1 $(hostname)" | sudo tee --append /etc/hosts


cat <<EOF>> /etc/consul.d/consul.hcl
datacenter          = "${local_region}"
leave_on_terminate  = true
advertise_addr      = "$${local_ipv4}"
data_dir            = "/opt/consul/data"
client_addr         = "0.0.0.0"
log_level           = "INFO"
ui                  = true
retry_join          = ["provider=aws tag_key=Environment-Name tag_value=${environment_name}"]
disable_remote_exec = false
EOF

chown consul:consul /etc/consul.d/consul.hcl
systemctl start consul

systemctl daemon-reload

while [ "x$${consul_leader_http_code}" != "x200" ] ; do
  echo "Waiting for Consul to get a leader..."
  sleep 5
  consul_leader_http_code=$(curl --silent --output /dev/null --write-out "%{http_code}" "http://127.0.0.1:8500/v1/operator/raft/configuration") || consul_leader_http_code=""
done

for region in ${remote_regions}; do
  while [ "x$${wan_consul_leader_http_code}" != "x200" ] ; do
    echo "Waiting for Consul WAN join to $${region} to complete..."
    sleep 5
    wan_consul_leader_http_code=$(curl --silent --output /dev/null --write-out "%{http_code}" "http://127.0.0.1:8500/v1/operator/raft/configuration?dc=$${region}") || consul_leader_http_code=""
  done
done

# consul read/write functions
cget() { curl -sf http://127.0.0.1:8500/v1/kv/service/vault/$1?raw; }
cput() { curl -sfX PUT --output /dev/null http://127.0.0.1:8500/v1/kv/service/vault/$1 -d $2; }


if [ "${vault_cloud_auto_init_and_unseal}" = true ] ; then
  for region in ${local_region} ${remote_regions}; do
    echo "Initializing Vault cluster in $${region}"
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
  
    sleep 5
    
    echo "Restarting Vault standby nodes using Consul exec"
    consul exec -datacenter=$${region} -service vault -tag standby sudo systemctl restart vault
  done
  
  if [ "${vault_auto_replication_setup}" = true ] ; then
    echo "Enabling Performance replication in local Vault cluster (primary)"
    LOCAL_ACTIVE_VAULT=$(curl -s http://127.0.0.1:8500/v1/catalog/service/vault?tags=active | jq -r '.[0].Address')
    curl \
        --header "X-Vault-Token: $(cget ${local_region}-root-token)" \
        --request POST \
        --data '{}' \
        --silent \
        http://$${LOCAL_ACTIVE_VAULT}:8200/v1/sys/replication/performance/primary/enable
    
    
    for region in ${remote_regions}; do
      echo "Generating Vault performance replication token for $${region} Vault cluster"
      curl \
          --header "X-Vault-Token: $(cget ${local_region}-root-token)" \
          --request POST \
          --data '{"id": "'"$${region}-perf-secondary"'"}' \
          --silent \
          http://$${LOCAL_ACTIVE_VAULT}:8200/v1/sys/replication/performance/primary/secondary-token | tee \
          >(jq --raw-output '.wrap_info .token' > /tmp/$${region}-perf-secondary-token)
      
      REMOTE_ACTIVE_VAULT=$(curl -s "http://127.0.0.1:8500/v1/catalog/service/vault?dc=$${region}&tag=active" | jq -r '.[0].Address')
      REPL_TOKEN=$(cat /tmp/$${region}-perf-secondary-token)
      
      echo "Enabling Vault performance replication on $${region} Vault cluster (secondary)"
      curl \
          --header "X-Vault-Token: $(cget $${region}-root-token)" \
          --request POST \
          --data '{"token": "'"$REPL_TOKEN"'"}' \
          --silent \
          http://$${REMOTE_ACTIVE_VAULT}:8200/v1/sys/replication/performance/secondary/enable 
      
      # sleep while replication setup completes
      # fresh cluster will be fast - is there a status we can poll?
      sleep 15
   
      echo "Restarting Vault standby nodes using Consul exec"
      consul exec -datacenter=$${region} -service vault -tag standby sudo systemctl restart vault
    done
  fi
fi
export VAULT_ADDR="http://active.vault.service.consul:8200"
export VAULT_TOKEN=$(cat /tmp/${local_region}-root-token)
export SSH_USER=${ssh_user_name}
export ENVIRONMENT_NAME=${environment_name}
export LOCAL_REGION=${local_region}
export REMOTE_REGIONS="${remote_regions}"
export AWS_AUTH_ACCESS_KEY=${aws_auth_access_key}
export AWS_AUTH_SECRET_KEY=${aws_auth_secret_key}
export HASHISTACK_INSTANCE_ARN=${hashistack_instance_arn}
export AVIATO_INSTANCE_ARN=${aviato_instance_arn}
/usr/bin/vault_setup.sh