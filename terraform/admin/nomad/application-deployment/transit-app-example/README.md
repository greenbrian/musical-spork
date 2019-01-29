TODO: ELB, HAProxy

# Transit-app-example
This example demonstrates the Vault Transit secret engine with a python application for encryption/decryption of database records.

The application and deployed image are built via this repository: https://github.com/AdamCavaliere/transit-app-example

## Steps (Fabio)

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