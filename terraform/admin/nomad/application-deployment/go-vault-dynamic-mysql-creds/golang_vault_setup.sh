#!/bin/bash

consul kv get service/vault/us-east-1-root-token | vault auth -

POLICY='path "database/creds/readonly" { capabilities = [ "read", "list" ] }'

echo $POLICY > policy-mysql.hcl

vault policy-write mysql policy-mysql.hcl
