## Golang App Deployment with dynamic database credentials

```bash
$ chmod +x golang_vault_setup.sh
$ ./golang_vault_setup.sh
$ nomad run application.nomad
```
Now we can drill down on the app logs

```bash
$ nomad status app
. . .
Allocations
ID        Node ID   Task Group  Version  Desired  Status   Created  Modified
3d01fe8d  78885a75  app         0        run      running  4s ago   2s ago
89aa2df4  1555a5bf  app         0        run      running  4s ago   2s ago
f1dd01de  315e9c08  app         0        run      running  4s ago   2s ago
```

Check the logs of an alloc, you should see the dyamic creds
```bash
$ nomad logs -stderr 3d01fe8d
2018/08/08 15:48:03 Starting Go App
2018/08/08 15:48:03 Getting database credentials...
2018/08/08 15:48:03 username v-read-uKOR92cRd, password A1a-VHNvEj9Xkk0sIURD
2018/08/08 15:48:03 Initializing database connection pool...
2018/08/08 15:48:03 HTTP service listening on 10.0.1.192:8080
2018/08/08 15:48:03 Renewing credentials: database/creds/readonly/bd9a9211-776c-359e-6c3f-f02578e3b4a6
```

Hop back to the Vault GUI and revoke the database creds via their leases.
```bash
http://ak-hs-b7947d86-vault-1073633556.us-east-1.elb.amazonaws.com:8200/ui/vault/access/leases/list
```

Once revoked you can take a look at the database if you would like. (It should be empty after the leases are revoked, I haven't done that here).

```bash

$ sudo yum install -y mariadb-server
$ mysql -h $(dig +short db.service.consul | sed -n 1p) -u vaultadmin -pvaultadminpassword

MariaDB [(none)]> SELECT User FROM mysql.user;
+------------------+
| User             |
+------------------+
| v-read-3uZU2tm2z |
| v-read-uKOR92cRd |
| v-read-w4YV1KD53 |
| vaultadmin       |
| root             |
+------------------+
```