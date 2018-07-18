#!/usr/bin/env bash

set -e
set -o pipefail

VAULT_ADDR="http://active.vault.service.consul:8200"
IAM_ROLE_NAME="test-role-iam"
VAULT_HEADER_VALUE=""
VAULT_TOKEN_FILE_PATH=/secrets
VAULT_TOKEN_FILE=${VAULT_TOKEN_FILE_PATH}/nomad-server-token
VAULT_LOGIN_RESPONSE=/tmp/response

if hash vault 2>/dev/null; then
  echo "Vault binary version located, version $(vault --version)"
else
  echo "Vault binary not found, exiting."
  exit 1
fi

mkdir -p $VAULT_TOKEN_FILE_PATH

token_fetch() {
      vault login \
      -format=json \
      -no-store \
      -tls-skip-verify \
      -address=${VAULT_ADDR} \
      -method=aws \
      role=${IAM_ROLE_NAME} > $VAULT_LOGIN_RESPONSE
    echo $?
}

until [ "$(token_fetch)" -eq "0" ]
do
  echo "Waiting for Vault token for Nomad.."
  sleep 5
done

echo "Vault token for Nomad successfully obtained"
token=$(jq -r .auth.client_token $VAULT_LOGIN_RESPONSE)
echo "VAULT_TOKEN=$token" > $VAULT_TOKEN_FILE
rm -f $VAULT_LOGIN_RESPONSE


## vault login -method=aws role=test-role-iam
## Success! You are now authenticated. The token information displayed below
## is already stored in the token helper. You do NOT need to run "vault login"
## again. Future Vault requests will automatically use this token.
## 
## WARNING! The following warnings were returned from Vault:
## 
##   * TTL of "768h0m0s" exceeded the effective max_ttl of "500h0m0s"; TTL value
##   is capped accordingly
## 
## Key                                Value
## ---                                -----
## token                              1c7fbea1-42c3-31de-9123-c52e6b6ae106
## token_accessor                     1e177621-1b57-a4e3-0f33-7db723fb4355
## token_duration                     500h
## token_renewable                    true
## token_policies                     [default nomad-server]
## token_meta_inferred_entity_type    n/a
## token_meta_account_id              379754991775
## token_meta_auth_type               iam
## token_meta_canonical_arn           arn:aws:iam::379754991775:role/hashistack-omni-39110682
## token_meta_client_arn              arn:aws:sts::379754991775:assumed-role/hashistack-omni-39110682/i-03dcb111ce547fae3
## token_meta_client_user_id          AROAI7XDGSRZ422SQAFYG
## token_meta_inferred_aws_region     n/a
## token_meta_inferred_entity_id      n/a