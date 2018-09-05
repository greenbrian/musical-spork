## Nginx Deployment (Template Example) with Vault secret
Deploy nginx on Nomad. Uses Vault for secrets deployment

```bash
$ chmod +x kv_vault_setup.sh
$ ./kv_vault_setup.sh
$ nomad run nginx-kv-secret.nomad
```
Check results using Fabio. 

```bash
http://ak-hs-9a0ff0bb-fabio-4220c9210d8e0876.elb.us-east-1.amazonaws.com:9999/nginx-secret/
```
