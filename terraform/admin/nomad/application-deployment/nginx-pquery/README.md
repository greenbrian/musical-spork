Start the nomad applications in each region.<br>

```
nomad job run profit-us-east-1.hcl
nomad job run profit-us-west-2.hcl
```

Execute this from the client node in each region(or the admin node in the admin region).  The client/admin node is important because if you issue the request from a node who is running the service it will always choose the local service which makes the demo slightly less impressive.

```
watch -n 1 curl -s http://profitapp.query.consul:8080
```


Demonstrate that each region receives local results that rotates through the AZ's and each has unique Vault Tokens and AWS dynamic credentials.
```
nomad job stop -purge -region us-west-2 profit
```
The client in us-west-2 fails over to us-east-1 services.

Bring the service back, and it fails back.
```
nomad job run profit-us-west-2.hcl
```
Drop the east side and it fails over to west.
```
nomad job stop -purge -region us-east-1 profit
```
Bring it back.
```
nomad job run profit-us-east-1.hcl
```

If this is a demo showing off consul configuration management or nomad/vault integrations, you can now go in via the consul ui and change one of the fruits for yellow/magenta to pear/grape/etc. and watch as the instances restart and show the new fruit result without interaction.<br>

us-east-1/us-west-2
```
kv/service/profitapp/yellow/fruit
kv/service/profitapp/magenta/fruit
```
You can also point out that as the 1minute TTL on the AWS secret is expiring the nodes are restarting and fetching a new secret.  If the TTL were longer it may renew the creds vs. getting fresh ones each time.

For a deeper dive into prepared queries you can go down the variations of prepared queries profityellow/profitmagenta/profitnearby to show tag filtering and sorting results based on RTT from agent. Using dig is nice for the RTT sorting to compare RR DNS results vs. static result order based on RTT.  Currently profitmagenta/profitnearby aren't automatically executed on environment standup so they have to be manually executed for each region.
```
watch -n 1 curl -s http://profityellow.query.consul:8080
```


```
  curl \
      --header "Content-Type: application/json" \
      --request POST \
      --data '{
                "Name": "",
                "Template": {
                  "Type": "name_prefix_match"
                },
                "Service": {
                  "Service": "$${name.full}",
                  "Failover": {
                    "NearestN": 3
                  },
                  "OnlyPassing": true
                }
             }' \
      --silent \
      http://127.0.0.1:8500/v1/query?dc=$${region}
  curl \
      --header "Content-Type: application/json" \
      --request POST \
      --data '{
                "Name": "profityellow",
                "Service": {
                  "Service": "profitapp",
                  "Failover": {
                    "NearestN": 3
                  },
                  "OnlyPassing": true,
                  "Near": "",
                  "Tags": ["profit", "yellow"],
                  "NodeMeta": null
                },
                "DNS": {
                  "TTL": ""
                }
              }' \
      --silent \
      http://127.0.0.1:8500/v1/query?dc=$${region}
  curl \
      --header "Content-Type: application/json" \
      --request POST \
      --data '{
                "Name": "profitmagenta",
                "Service": {
                  "Service": "profitapp",
                  "Failover": {
                    "NearestN": 3
                  },
                  "OnlyPassing": true,
                  "Near": "",
                  "Tags": ["profit", "magenta"],
                  "NodeMeta": null
                },
                "DNS": {
                  "TTL": ""
                }
              }' \
      --silent \
      http://127.0.0.1:8500/v1/query?dc=$${region}
  curl \
      --header "Content-Type: application/json" \
      --request POST \
      --data '{
                "Name": "profitclose",
                "Service": {
                  "Service": "profitapp",
                  "Failover": {
                    "NearestN": 3
                  },
                  "OnlyPassing": true,
                  "Near": "_agent",
                  "NodeMeta": null
                },
                "DNS": {
                  "TTL": ""
                }
              }' \
      --silent \
      http://127.0.0.1:8500/v1/query?dc=$${region}
```
