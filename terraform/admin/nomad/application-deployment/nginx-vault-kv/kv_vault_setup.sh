#!/bin/bash

consul kv get service/vault/us-east-1-root-token | vault auth -

vault write secret/test message='Live demos rock!!!'

cat << EOF > test.policy
path "secret/*" {
    capabilities = ["create", "read", "update", "delete", "list"]
}
EOF

vault policy-write test test.policy
