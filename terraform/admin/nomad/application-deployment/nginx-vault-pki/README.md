## Nginx Deployment (Template Example) with Vault secret (PKI Backend)
Deploy nginx on Nomad. Uses Vault for secrets deployment

```bash
$ chmod +x pki_vault_setup.sh
$ ./pki_vault_setup.sh
$ nomad run nginx-pki-secret.nomad
```
Check results using Fabio. 

```bash
http://ak-hs-9b98de38-fabio-c0b6f36b1a309891.elb.us-east-1.amazonaws.com:9999/nginx-secret/
```
