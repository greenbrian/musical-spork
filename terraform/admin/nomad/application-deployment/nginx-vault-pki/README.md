# Nomad-Vault Nginx PKI

### TLDR;
```bash
vagrant@node1:/vagrant/vault-examples/nginx/PKI$ ./pki_vault_setup.sh

vagrant@node1:/vagrant/vault-examples/nginx/PKI$ nomad run nginx-pki-secret.nomad

#visit your browser (If using Vagrantfile). Job uses static port 443
https://localhost:9443/
```
