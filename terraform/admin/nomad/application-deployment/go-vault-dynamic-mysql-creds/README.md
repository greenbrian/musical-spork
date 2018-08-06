# Golang Application + Dynamic Database Credentials (MySQL) 
This guide will discuss native app library integration and dynamic database credentials with Nomad, Vault, and MySQL. It will also show revoking those dynamic database credentials with Vault's GUI.

#### TLDR;
Using Vagrantfile setup:
```bash
vagrant@node1:/vagrant/vault-examples/goapp$ ./golang_vault_setup.sh

vagrant@node1:/vagrant/vault-examples/goapp$ nomad run application.nomad

vagrant@node1:/vagrant/vault-examples/goapp$ nomad status app

#Pull an alloc id from status, logs show dynamic username password
vagrant@node1:/vagrant/vault-examples/goapp$ nomad logs -stderr 435bf5cd
. . .
2018/01/04 20:28:49 username v-read-40xpu913r, password A1a-73r2ywpqx6wrqqts

#On Node3 
vagrant@node3:~$ mysql -h 192.168.50.152 -u vaultadmin -pvaultadminpassword
MariaDB [(none)]> SELECT User FROM mysql.user;
+------------------+
| User             |
+------------------+
| v-read-40xpu913r |
| v-read-q5sr6rzrz |
| v-read-xr3v2yrsr |
| vaultadmin       |
| root             |
+------------------+

#login to Vault GUI
username: vault   password: vault
http://localhost:8200/ui/vault/auth?with=userpass

#revoke database credentials:
http://localhost:8200/ui/vault/leases/list/mysql/creds/app/

#Show database users/passwords deleted in mysql
MariaDB [(none)]> SELECT User FROM mysql.user;
+------------+
| User       |
+------------+
| vaultadmin |
| root       |
+------------+

#Optional: App output is simple, you can check in browser as well http://localhost:8080
vagrant@node1:/vagrant/vault-examples/goapp$ curl http://10.0.2.15:8080
{"message":"Hello"}
```
