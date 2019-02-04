TODO: ELB, HAProxy

# Transit-app-example
This example demonstrates the Vault Transit secret engine with a python application for encryption/decryption of database records.

The application and deployed image are built via this repository: https://github.com/AdamCavaliere/transit-app-example

## Access the Transit App (Terraform automatically deployed)
Open the URL from your terraform output:
```bash
vault-Transit-App-Demo = http://ak-hashistack-fe79aebb-fabio-4155744d59671ccd.elb.us-east-1.amazonaws.com:9999
```

## See DBView in the app
1. Encrypted secret data in database (Protected from SQL Dump)
2. Unique DB creds per container/app-instance

## Dynamic Secrets: Auditing 
Note: "remote_address" and unique data credentials in responses
```
CONTAINER #1
  "request": {
    "id": "5de91ec2-98ae-2456-48a2-8b7ddab45ce8",
    "operation": "read",
    "client_token": "s.zbT7BAHHUJzHSVpd5J5CTNyo",
    "client_token_accessor": "3d3HSaipAqLB8cB4rnT4DwEI",
    "namespace": {
      "id": "root",
      "path": ""
    },
    "path": "lob_a/workshop/database/creds/workshop-app",
    "data": null,
    "policy_override": false,
    "remote_address": "10.0.3.200",
    "wrap_ttl": 0,
    "headers": {}
  },
  "response": {
    "secret": {
      "lease_id": "lob_a/workshop/database/creds/workshop-app/1Me3Y9OmYSQqyAJ7xrLedIl7"
    },
    "data": {
      "password": "A1a-48fc2TXTCtaqdQ4A",
      "username": "v-token-d686-workshop-a-4iHQsis5"
    }
  },

CONTAINER #2
 "request": {
    "id": "110932ca-d3a5-52b6-d641-7d87153c3564",
    "operation": "read",
    "client_token": "s.23PKwyoOQV2ooGSTpLFm5L7s",
    "client_token_accessor": "5xzsDvtDUCIuPH9eHiv1PNEw",
    "namespace": {
      "id": "root",
      "path": ""
    },
    "path": "lob_a/workshop/database/creds/workshop-app",
    "data": null,
    "policy_override": false,
    "remote_address": "10.0.1.40",
    "wrap_ttl": 0,
    "headers": {}
  },
  "response": {
    "secret": {
      "lease_id": "lob_a/workshop/database/creds/workshop-app/1NHyw73j6EhgDWZ9J4js6FJj"
    },
    "data": {
      "password": "A1a-6RZfjDwZCOgqeuc0",
      "username": "v-token-d933-workshop-a-1flDJjuC"
    }
```









## Manual Steps (Fabio)

First SSH into the admin node (found via Terraform output)
```bash
admin-ssh-us-east-1 = connect to host with following command: ssh ec2-user@3.93.54.250 -i private_key.pem
```

Run the following commands from the musical-spork admin node

```bash
#adjust for your OS user 
nomad run /home/ec2-user/nomad/fabio-us-east-1.nomad
nomad run /home/ec2-user/nomad/application-deployment/transit-app-example/transit-app-example.nomad
```

Now access fabio. The fabio URL is in your Terraform output from the apply.
For example, this will take you to the Fabio UI (adjust for the actual URL in your terraform output)
```bash
fabio-ui-us-east-1 = http://ak-hashistack-d3f4599a-fabio-fa32369f45eccbe5.elb.us-east-1.amazonaws.com:9998
```

To access the app. use port 9999.
```bash
http://ak-hashistack-d3f4599a-fabio-fa32369f45eccbe5.elb.us-east-1.amazonaws.com:9999/"
```

You can change the URL paths via the Nomad job file under the task's "tags"