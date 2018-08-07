#!/usr/bin/env bash

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
new_hostname="hashistack-$${instance_id}"

echo "${private_key}" > /home/${ssh_user_name}/.ssh/id_rsa
chmod 0700 /home/${ssh_user_name}/.ssh
chmod 0600 /home/${ssh_user_name}/.ssh/id_rsa
chown ${ssh_user_name}:${ssh_user_name} /home/${ssh_user_name}/.ssh/id_rsa

#Add localhost to /etc/resolv.conf to resolve dns
sudo sed -i '1s/^/nameserver 127.0.0.1\n/' /etc/resolv.conf

#add hostname to /etc/hosts
sudo echo "127.0.0.1 $${hostname}" | sudo tee --append /etc/hosts

# set the hostname (before starting consul and nomad)
hostnamectl set-hostname "$${new_hostname}"

echo "${private_key}" > /home/ubuntu/.ssh/id_rsa
chmod 0700 /home/ubuntu/.ssh
chmod 0600 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa

# ensure dnsmasq is part of name resolution
sudo sed '1 i nameserver 127.0.0.1' -i /etc/resolv.conf

cat <<EOF>> /etc/consul.d/consul.json
{
  "datacenter": "${local_region}",
  "leave_on_terminate": true,
  "advertise_addr": "$${local_ipv4}",
  "data_dir": "/opt/consul/data",
  "client_addr": "0.0.0.0",
  "log_level": "INFO",
  "ui": true,
  "retry_join": ["provider=aws tag_key=Environment-Name tag_value=${environment_name}"]
}
EOF
chown consul:consul /etc/consul.d/consul.json


# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

if [[ ! -z $${YUM} ]]; then
sudo yum install -y mariadb-server
sudo service mariadb start
sudo mysqladmin -u root password R00tPassword
sudo mysql -u root -p'R00tPassword' << EOF
GRANT ALL PRIVILEGES ON *.* TO 'vaultadmin'@'%' IDENTIFIED BY 'vaultadminpassword' WITH GRANT OPTION;
CREATE DATABASE app;
FLUSH PRIVILEGES;
EOF
elif [[ ! -z $${APT_GET} ]]; then
sudo apt-get install -y mariadb-server
sudo mysqladmin -u root password R00tPassword
sudo mysql -u root -p'R00tPassword' << EOF
GRANT ALL PRIVILEGES ON *.* TO 'vaultadmin'@'%' IDENTIFIED BY 'vaultadminpassword' WITH GRANT OPTION;
CREATE DATABASE app;
FLUSH PRIVILEGES;
EOF
sudo sed -i 's/bind-address/#bind-address/g' /etc/mysql/mariadb.conf.d/50-server.cnf
sudo service mysql restart;
else
  exit 1;
fi


echo '{"service": {"name": "db", "tags": ["mysql"], "port":3306}}' | sudo tee /etc/consul.d/mysql.json

# start consul once it is configured correctly
systemctl start consul
