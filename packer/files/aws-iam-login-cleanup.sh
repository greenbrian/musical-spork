#!/usr/bin/env bash

set -e
set -o pipefail

VAULT_ADDR="http://active.vault.service.consul:8200"
IAM_ROLE_NAME="test-role-iam"
VAULT_HEADER_VALUE=""
VAULT_TOKEN_FILE_PATH=/secrets
VAULT_TOKEN_FILE=${VAULT_TOKEN_FILE_PATH}/nomad-server-token
VAULT_LOGIN_RESPONSE=/tmp/response

rm -f $VAULT_TOKEN_FILE
rm -f $VAULT_LOGIN_RESPONSE