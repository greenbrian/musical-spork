Open up incognito browser

1. Requires fabio running in us-east-1

2. Launch all 4 jobs

3. Check your terraform output for the correct url
```
fabio-router-haproxy = http://ak-hs-33501899-fabio-1869051b5c81006f.elb.us-east-1.amazonaws.com:9999/haproxy
```

4. Create an intention (Deny)

```
consul intention create -deny -replace web goapp
```

5. Refresh browser. it should not connect.
