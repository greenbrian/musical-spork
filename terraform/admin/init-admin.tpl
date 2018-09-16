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

# wait for local Consul cluster
while [ "x$${consul_leader_http_code}" != "x200" ] ; do
  echo "Waiting for Consul to get a leader..."
  sleep 5
  consul_leader_http_code=$(curl --silent --output /dev/null --write-out "%{http_code}" "http://127.0.0.1:8500/v1/operator/raft/configuration") || consul_leader_http_code=""
done

# wait for WAN join to complete
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


# Set NOMAD_ADDR to connect to local Nomad cluster
sudo cat << EOF > /etc/profile.d/nomad.sh
export NOMAD_ADDR="http://nomad-server.service.consul:4646"
EOF
sudo cat << EOF > /etc/profile.d/vault.sh
export VAULT_ADDR="http://active.vault.service.consul:8200"
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

# Setup Nomad integration with Vault
# https://www.nomadproject.io/docs/vault-integration/index.html

echo "Configuring Vault policy for Nomad"
curl https://nomadproject.io/data/vault/nomad-server-policy.hcl -O -s -L
vault policy write nomad-server nomad-server-policy.hcl

echo "Creating Vault token role for Nomad"
curl https://nomadproject.io/data/vault/nomad-cluster-role.json -O -s -L
vault write /auth/token/roles/nomad-cluster @nomad-cluster-role.json


echo "Enable AWS authentication method via REST API"
LOCAL_ACTIVE_VAULT=$(curl -s http://127.0.0.1:8500/v1/catalog/service/vault?tags=active | jq -r '.[0].Address')
aws_auth_payload=$(cat <<EOF
{
  "type": "aws",
  "description": "AWS authentication setup"
}
EOF
)

curl \
    --silent \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data "$${aws_auth_payload}" \
    http://$${LOCAL_ACTIVE_VAULT}:8200/v1/sys/auth/aws

echo "Configure AWS credentials in Vault for AWS authentication method"
curl \
    --silent \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data '{ "access_key": "${aws_auth_access_key}", "secret_key": "${aws_auth_secret_key}"}' \
    http://$${LOCAL_ACTIVE_VAULT}:8200/v1/auth/aws/config/client

echo "Configure AWS role in Vault for AWS authentication method"
nomad_role_payload=$(cat <<EOF
{
  "auth_type": "iam",
  "bound_iam_principal_arn": "${hashistack_instance_arn}",
  "policies": "nomad-server",
  "max_ttl": "500h"
}
EOF
)

curl \
    --silent \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data "$${nomad_role_payload}" \
    http://$${LOCAL_ACTIVE_VAULT}:8200/v1/auth/aws/role/nomad

echo "Configure AWS role in Vault for AWS authentication method"
aviato_role_payload=$(cat <<EOF
{
  "auth_type": "iam",
  "bound_iam_principal_arn": "${aviato_instance_arn}",
  "policies": "aviato",
  "max_ttl": "500h"
}
EOF
)

curl \
    --silent \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data "$${aviato_role_payload}" \
    http://$${LOCAL_ACTIVE_VAULT}:8200/v1/auth/aws/role/aviato



echo "Running Fabio load balancer as Nomad job"
export NOMAD_ADDR="http://$(curl -s http://127.0.0.1:8500/v1/catalog/service/nomad-server?dc=${local_region} | jq -r '.[0].Address'):4646"
nomad run /home/ec2-user/nomad/fabio-${local_region}.nomad


######################
#Vault secret backends
######################

#TRANSIT SECRETS ENGINE
vault secrets enable transit
vault write -f transit/keys/go-app

#KV Secrets Engine
vault secrets enable -path=supersecret kv
vault write supersecret/admin admin_user=root admin_password=P@55w3rd
vault secrets enable -path=verysecret kv
vault write verysecret/sensitive key=value password=35616164316lasfdasfasdfasdfasdfasf

#AppRole
# USAGE:
# vault read auth/approle/role/my-role/role-id
# vault write -f auth/approle/role/my-role/secret-id
# vault write auth/approle/login role_id=  secret_id=
vault auth enable approle
vault write auth/approle/role/my-role \
    secret_id_ttl=10m \
    token_num_uses=10 \
    token_ttl=20m \
    token_max_ttl=30m \
    policies=vault-admin \
    secret_id_num_uses=40


#PKI SECRETS ENGINE
# USAGE
# vault write pki/issue/consul-service \
#    common_name=www.my-website.service.consul
vault secrets enable pki
vault secrets tune -max-lease-ttl=8760h pki
vault write pki/root/generate/internal \
    common_name=service.consul \
    ttl=8760h
vault write pki/config/urls \
    issuing_certificates="http://active.vault.service.consul:8200/v1/pki/ca" \
    crl_distribution_points="http://active.vault.service.consul:8200/v1/pki/crl"
vault write pki/roles/consul-service \
    allowed_domains="service.consul" \
    allow_subdomains=true \
    max_ttl=72h
vault write pki/issue/consul-service \
    common_name=nginx.service.consul \
    ttl=2h
POLICY='path "*" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }'
echo $POLICY > policy-superuser.hcl
vault policy-write superuser policy-superuser.hcl

#DATABASE SECRETS ENGINE
# USAGE
# vault read database/creds/readonly
vault secrets enable database
vault write database/config/mysql \
  plugin_name=mysql-legacy-database-plugin \
  connection_url="vaultadmin:vaultadminpassword@tcp(db.service.consul:3306)/"  \
  allowed_roles="readonly"
vault write database/roles/readonly \
  db_name=mysql \
  creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';" \
  default_ttl="30m" \
  max_ttl="24h"

#SSH-CA
# USAGE
# Use the ssh-client-signer backend in the GUI to sign your public key
# Save resulting key as ~/.ssh/id_rsa-cert.pub on your local machine
# ssh into the admin machine using the new signed cert
vault secrets enable -path=ssh-client-signer ssh
vault write -f -format=json ssh-client-signer/config/ca | jq -r '.data.public_key' > /home/ubuntu/trusted-user-ca-keys.pem
vault write ssh-client-signer/roles/my-role -<<"EOH"
{
  "allow_user_certificates": true,
  "allowed_users": "*",
  "default_extensions": [
    {
      "permit-pty": ""
    }
  ],
  "key_type": "ca",
  "default_user": "ubuntu",
  "ttl": "30m0s"
}
EOH


#AWS SECRETS ENGINE
vault secrets enable aws
vault write aws/config/root \
access_key=${aws_auth_access_key}  \
secret_key=${aws_auth_secret_key}  \
region=${local_region}
vault write aws/config/lease lease=1m lease_max=5m
echo '
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": ["arn:aws:s3:::vault-demo"]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject"
      ],
      "Resource": ["arn:aws:s3:::vault-demo/*"]
    }
  ]
}' > iam.policy
vault write aws/roles/s3access policy=@iam.policy

#### Aviato demo
# write some basic consul kv pairs
curl -fX PUT 127.0.0.1:8500/v1/kv/aviato/color/favorite -d YELLOW
curl -fX PUT 127.0.0.1:8500/v1/kv/aviato/number/huge -d 99999

# enable kv path for demo
vault secrets enable -version=1 -path=aviato kv

# write some Vault secrets
vault kv put aviato/info User1SSN="200-23-9930" User2SSN="000-00-0002" ttl=60s

mkdir -p /tmp/certs/

# Mount Root CA and generate cert
vault secrets enable -path aviato-root pki
vault secrets tune -max-lease-ttl=87600h aviato-root
vault write -format=json aviato-root/root/generate/internal \
common_name="aviato-root" ttl=87600h | tee \
>(jq -r .data.certificate > /tmp/certs/ca.pem) \
>(jq -r .data.issuing_ca > /tmp/certs/issuing_ca.pem) \
>(jq -r .data.private_key > /tmp/certs/ca-key.pem)

# Mount Intermediate and set cert
vault secrets enable -path aviato-intermediate pki
vault secrets tune -max-lease-ttl=87600h aviato-intermediate
vault write -format=json aviato-intermediate/intermediate/generate/internal \
  common_name="aviato-intermediate" ttl=43800h | tee \
  >(jq -r .data.csr > /tmp/certs/aviato-intermediate.csr) \
  >(jq -r .data.private_key > /tmp/certs/aviato-intermediate.pem)

# Sign the intermediate certificate and set it
vault write -format=json aviato-root/root/sign-intermediate \
  csr=@/tmp/certs/aviato-intermediate.csr \
  common_name="aviato-intermediate" ttl=43800h | tee \
  >(jq -r .data.certificate > /tmp/certs/aviato-intermediate.pem) \
  >(jq -r .data.issuing_ca > /tmp/certs/aviato-intermediate_issuing_ca.pem)
vault write aviato-intermediate/intermediate/set-signed \
  certificate=@/tmp/certs/aviato-intermediate.pem

# Generate the roles
vault write aviato-intermediate/roles/aviato-dot-com allow_any_name=true max_ttl="1m"

echo "
  path \"aviato-intermediate/issue*\" {
    capabilities = [\"create\",\"update\"]
  }
  path \"aviato/info*\" {
    capabilities = [\"read\"]
  }
  path \"auth/token/renew\" {
    capabilities = [\"update\"]
  }
  path \"auth/token/renew-self\" {
    capabilities = [\"update\"]
  }
  " | vault policy-write aviato -

echo "Configure AWS aviato role in Vault for AWS authentication method"
aviato_role_payload=$(cat <<EOF
{
  "auth_type": "iam",
  "bound_iam_principal_arn": "${aviato_instance_arn}",
  "policies": "aviato",
  "max_ttl": "500h"
}
EOF
)

curl \
    --silent \
    --header "X-Vault-Token: $${VAULT_TOKEN}" \
    --request POST \
    --data "$${aviato_role_payload}" \
    http://$${LOCAL_ACTIVE_VAULT}:8200/v1/auth/aws/role/aviato


# cleanup Vault details from Consul kv
curl -sfX DELETE  http://127.0.0.1:8500/v1/kv/service/vault?recurse

