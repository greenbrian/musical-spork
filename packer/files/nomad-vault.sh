#!/usr/bin/env bash

if [ -f /mnt/ramdisk/token ]; then 
  exec /usr/local/bin/nomad agent \
  -config=/etc/nomad.d \
  -vault-token=$(vault unwrap -field=token $(jq -r '.token' /mnt/ramdisk/token)) \
  -vault-tls-skip-verify=true
else
  echo "Nomad service failed due to missing Vault token"
  exit 1
fi