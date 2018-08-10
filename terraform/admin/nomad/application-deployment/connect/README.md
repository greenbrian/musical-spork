Open up incognito browser

1. Requires fabio running in us-east-1 (Should be running by default). If not: 
```bash
$ nomad run /home/$(whoami)/nomad/fabio-us-east-1.nomad
```


2. Launch all 4 jobs:

```bash
nomad run go-app-connect-proxy.nomad
nomad run go-app.nomad
nomad run haproxy-connect-proxy.nomad
nomad run haproxy.nomad
```



3. Check your terraform output for the correct url
`
fabio-router-haproxy = http://ak-hs-33501899-fabio-1869051b5c81006f.elb.us-east-1.amazonaws.com:9999/haproxy
`
You should see a golang app running that checks the version of Golang.

4. Create an intention (Deny)

`
consul intention create -deny -replace web goapp
`

Or use the Consul GUI:
`consul-ui-us-east-1 = http://52.54.81.114:8500/ui`

5. Refresh browser. it should not connect. 404
