#!/usr/bin/env bash

exec 1> >(logger -s -t $(basename $0)) 2>&1

instance_id="$(curl -s http://169.254.169.254/latest/meta-data/instance-id)"
local_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"
public_ipv4="$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
new_hostname="hashistack-client"

echo "${private_key}" > /home/${ssh_user_name}/.ssh/id_rsa
chmod 0700 /home/${ssh_user_name}/.ssh
chmod 0600 /home/${ssh_user_name}/.ssh/id_rsa
chown ${ssh_user_name}:${ssh_user_name} /home/${ssh_user_name}/.ssh/id_rsa

# set the hostname (before starting consul and nomad)
hostnamectl set-hostname "$${new_hostname}"


cat <<EOF>> /etc/consul.d/consul.hcl
datacenter          = "${local_region}"
leave_on_terminate  = true
advertise_addr      = "$${local_ipv4}"
data_dir            = "/opt/consul/data"
client_addr         = "0.0.0.0"
log_level           = "INFO"
ui                  = true
retry_join          = ["provider=aws tag_key=Environment-Name tag_value=${environment_name}"]
disable_remote_exec = false
EOF

chown consul:consul /etc/consul.d/consul.hcl
systemctl start consul

cat << EOF > /etc/systemd/system/consul-template.service
[Unit]
Description=consul-template agent
Requires=network-online.target
After=network-online.target consul.service
[Service]
Restart=on-failure
ExecStart=/usr/local/bin/consul-template -config=/etc/consul-template.d/consul-template.json
KillSignal=SIGINT
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
