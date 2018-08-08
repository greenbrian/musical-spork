## Nginx Deployment (Template Example)
Deploy nginx on Nomad. Uses Consul KV for configuration.

```bash
$ chmod +x kv_consul_setup.sh

$ ./kv_consul_setup.sh

$ nomad run nginx-consul.nomad
```
Check results using Fabio. 

```bash
http://ak-hs-9a0ff0bb-fabio-4220c9210d8e0876.elb.us-east-1.amazonaws.com:9999/nginx/
```
