#!/usr/bin/env bash

if [ -f /mnt/ramdisk/token ]; then
  exec env VAULT_TOKEN=$(vault unwrap -field=token $(jq -r '.token' /mnt/ramdisk/token)) \
      /usr/local/bin/consul-template \
        -config=/etc/consul-template.d \
        -vault-ssl-verify=false
else
  echo "Consul-template service failed due to missing Vault token"
  exit 1
fi
