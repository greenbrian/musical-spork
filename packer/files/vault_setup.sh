#!/usr/bin/env bash

# Setup Vault demo secret
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

curl -sX POST -H "X-Vault-Token: ${VAULT_TOKEN}" \
    http://${LOCAL_ACTIVE_VAULT}:8200/v1/sys/auth/aws \
    -d '{ "type": "aws", "description": "AWS authentication setup" }'

echo "Configure AWS credentials in Vault for AWS authentication method"
curl -sX POST -H "X-Vault-Token: ${VAULT_TOKEN}" \
    http://${LOCAL_ACTIVE_VAULT}:8200/v1/auth/aws/config/client \
    -d '{ "access_key": "'"${AWS_AUTH_ACCESS_KEY}"'", 
          "secret_key": "'"${AWS_AUTH_SECRET_KEY}"'"}'
   
echo "Configure AWS role in Vault for AWS authentication method"
curl -sX POST -H "X-Vault-Token: ${VAULT_TOKEN}" \
    http://${LOCAL_ACTIVE_VAULT}:8200/v1/auth/aws/role/nomad \
    -d '{ "auth_type": "iam",
          "bound_iam_principal_arn": "'"${HASHISTACK_INSTANCE_ARN}"'",
          "policies": "nomad-server",
          "max_ttl": "500h"
        }'

    
echo "Running Fabio load balancer as Nomad job"
export NOMAD_ADDR="http://$(curl -s http://127.0.0.1:8500/v1/catalog/service/nomad-server?dc=${LOCAL_REGION} | jq -r '.[0].Address'):4646"
nomad run /home/$SSH_USER/nomad/fabio-${LOCAL_REGION}.nomad


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

echo '
path "*" {
    capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}' | vault policy write superuser -

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
vault write -f -format=json ssh-client-signer/config/ca | jq -r '.data.public_key' > /home/$SSH_USER/trusted-user-ca-keys.pem
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
  "default_user": "$SSH_USER",
  "ttl": "30m0s"
}
EOH


#AWS SECRETS ENGINE
vault secrets enable aws
vault write aws/config/root \
  access_key=${AWS_AUTH_ACCESS_KEY}  \
  secret_key=${AWS_AUTH_SECRET_KEY}  \
  region=${LOCAL_REGION}
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
# write some consul kv data
consul kv put aviato/color/favorite YELLOW
consul kv put aviato/number/huge 9151133

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
  " | vault policy write aviato -
    
echo "Configure AWS role in Vault for AWS authentication method"
curl -sX POST -H "X-Vault-Token: ${VAULT_TOKEN}" \
    http://${LOCAL_ACTIVE_VAULT}:8200/v1/auth/aws/role/aviato \
    -d '{ "auth_type": "iam",
          "bound_iam_principal_arn": "'"${AVIATO_INSTANCE_ARN}"'",
          "policies": "aviato",
          "max_ttl": "500h"
        }'

#SENTINEL
sentinel_demo() {
cat <<EOF>> /tmp/business-hours.sentinel
import "time"
workdays = rule {
    time.now.weekday > 0 and time.now.weekday < 6
}
workhours = rule {
    time.now.hour > 9 and time.now.hour < 17
}
main = rule {
    workdays and workhours
}
EOF

cat <<EOF>> /tmp/cidr-check.sentinel
import "sockaddr"
import "strings"
precond = rule {
    request.operation in ["create", "update", "delete", "read"] and
    strings.has_prefix(request.path, "secret/")
}
cidrcheck = rule {
    sockaddr.is_contained(request.connection.remote_addr, "10.0.101.0/24")
}
main = rule when precond {
    cidrcheck
}
EOF

POLICY=$(base64 /tmp/business-hours.sentinel)
vault write sys/policies/egp/business-hours-check \
        policy="${POLICY}" \
        paths="secret/*" \
        enforcement_level="hard-mandatory"

 POLICY=$(base64 /tmp/cidr-check.sentinel)
 vault write sys/policies/egp/cidr-check \
        policy="${POLICY}" \
        paths="secret/cidr" \
        enforcement_level="advisory"
vault kv put secret/test foo=bar
vault kv put secret/cidr foo=bar
}
#sentinel_demo


vault --version | grep 0.11 ; if [ $? -eq 0 ] 
then 
  #Namespaces
  vault namespace create engineering
  vault namespace create -namespace=engineering development
  vault namespace create -namespace=engineering operations
  r

  #ACL Templating
  echo '
  path "secret/{{identity.entity.name}}/*" {
    capabilities = [ "create", "update", "read", "delete", "list" ]
  }
  path "secret/" {
    capabilities = ["list"]
  }' | vault policy write user-tmpl -
  vault write auth/userpass/users/bob password=vault 
  vault auth list -format=json | jq -r '.["userpass/"].accessor' > accessor.txt  
  vault write -format=json identity/entity name="bob_smith" policies="user-tmpl" \
          | jq -r ".data.id" > entity_id.txt
  vault write identity/entity-alias name="bob" \
        canonical_id=$(cat entity_id.txt) \
        mount_accessor=$(cat accessor.txt)
  # USAGE
  # vault login -method=userpass username=bob password=vault
  # vault kv put secret/bob_smith/test foo=ba
fi

# Add Consul Prepared Query Template for Auto Service Failover and scoped query to target tags
for region in ${LOCAL_REGION} ${REMOTE_REGIONS}; do
  curl -sX POST http://127.0.0.1:8500/v1/query?dc=${region} \
      -d '{ "Name": "", 
              "Template": { "Type": "name_prefix_match" },
              "Service": { 
                "Service": "${name.full}",
                "Failover": { "NearestN": 3 }, 
                "OnlyPassing": true }}' 
  
  curl -sX POST http://127.0.0.1:8500/v1/query?dc=${region} \
       -d '{ "Name": "profityellow",
             "Service" : {
               "Service": "profitapp",
               "Failover": { "NearestN": 3 },
               "OnlyPassing": true,
               "Near": "",
               "Tags": ["profit", "yellow"],
               "NodeMeta": null },
             "DNS": { "TTL": "" }}'
done

# Add Consul KV data for profitapp prepared query demo
for region in ${LOCAL_REGION} ${REMOTE_REGIONS}; do
  consul kv put -datacenter=${region} service/profitapp/yellow/fruit apple
  consul kv put -datacenter=${region} service/profitapp/magenta/fruit orange
done

# cleanup Vault details from Consul kv
curl -sfX DELETE  http://127.0.0.1:8500/v1/kv/service/vault?recurse