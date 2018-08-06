# Nginx Deployment (Template Example)
The goal of this guide is to help users deploy Nginx on Nomad. In the process we will also show how to use Nomad templating to update the configuration of our deployed tasks. (Nomad uses Consul Template under the hood) 

### TLDR;
```bash
vagrant@node1:/vagrant/application-deployment/nginx$ ./kv_consul_setup.sh

vagrant@node1:/vagrant/application-deployment/nginx$ nomad run nginx-consul.nomad

#Validate the results on Nomad clients, job assigns static port 8080 
#if using vagrantfile check:
http://localhost:8080/nginx/

```
