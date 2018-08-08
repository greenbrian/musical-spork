#!/bin/bash

vault auth -method=userpass username=vault password=vault

POLICY='path "database/creds/readonly" { capabilities = [ "read", "list" ] }'

echo $POLICY > policy-mysql.hcl

vault policy-write mysql policy-mysql.hcl