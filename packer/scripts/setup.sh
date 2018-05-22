#!/usr/bin/env bash
set -x

echo "Running"
echo "Installing base packages"
sudo apt-get -qq -y update
sudo apt-get install -qq -y awscli jq telnet vim wget unzip ntp git dnsmasq default-jdk

echo "Configuring system time"
sudo timedatectl set-timezone UTC
sudo systemctl start ntp.service
sudo systemctl enable ntp.service

echo "Disable reverse dns lookup in SSH"
sudo sh -c 'echo "\nUseDNS no" >> /etc/ssh/sshd_config'
sudo service ssh restart

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Configuring DNSmasq"
sudo bash -c "cat >/etc/dnsmasq.d/10-consul" << EOF
server=/consul/127.0.0.1#8600
EOF

echo "Enable DNSmasq"
sudo systemctl enable dnsmasq

echo "Disable firewall"
sudo ufw disable

echo "Adding Consul and Vault users"
# nomad runs as root
for _user in consul consul-template vault; do
  sudo addgroup --system ${_user} >/dev/null
  sudo adduser \
    --system \
    --disabled-login \
    --ingroup ${_user} \
    --home /srv/${_user} \
    --no-create-home \
    --gecos "${_user} account" \
    --shell /bin/false \
    ${_user}  >/dev/null
sudo mkdir -pm 0755 /srv/${_user}
sudo chown -R ${_user}:${_user} /srv/${_user}
sudo chmod -R 0755 /srv/${_user}
done

echo "Installing Consul, Consul-template, Nomad and Vault"
install_from_zip() {
  cd /tmp && {
    unzip -qq "${1}.zip"
    sudo mv "${1}" "/usr/local/bin/${1}"
    sudo chmod +x "/usr/local/bin/${1}"
    rm -rf "${1}.zip"
  }
 
  # create and manage permissions on directories
  sudo mkdir -pm 0755 /etc/${1}.d /opt/${1}/data /opt/${1}/tls
  sudo chown -R ${1}:${1} /etc/${1}.d /opt/${1}/data /opt/${1}/tls
  sudo chmod -R 0644 /etc/${1}.d/*
}
install_from_zip consul
install_from_zip consul-template
install_from_zip nomad
install_from_zip vault

echo "Copy systemd services"
systemd_files() {
  sudo cp /tmp/files/$1 /lib/systemd/system/
  sudo chmod 0664 /lib/systemd/system/$1
}
systemd_files consul.service
systemd_files consul-online.service
systemd_files consul-online.target
systemd_files nomad.service
systemd_files vault.service

sudo cp /tmp/files/consul-online.sh /usr/bin/consul-online.sh
sudo chmod +x /usr/bin/consul-online.sh
sudo systemctl enable consul-online

echo "Installing Docker for Nomad"
curl -sSL https://get.docker.com/ | sudo sh
sudo sh -c "echo \"DOCKER_OPTS='--dns 127.0.0.1 --dns 8.8.8.8 --dns-search service.consul'\" >> /etc/default/docker"
sudo systemctl enable docker


echo "Setup Hashistack profile"
cat <<PROFILE | sudo tee /etc/profile.d/hashistack.sh
export CONSUL_ADDR=http://127.0.0.1:8500
export NOMAD_ADDR=http://127.0.0.1:4646
export VAULT_ADDR=http://127.0.0.1:8200
#export VAULT_TOKEN=root
PROFILE

echo "Give consul user shell access for remote exec"
sudo /usr/sbin/usermod --shell /bin/bash consul >/dev/null

echo "Allow consul sudo access for echo, tee, cat, sed, and systemctl"
cat <<SUDOERS | sudo tee /etc/sudoers.d/consul
consul ALL=(ALL) NOPASSWD: /usr/bin/echo, /usr/bin/tee, /usr/bin/cat, /usr/bin/sed, /usr/bin/systemctl
SUDOERS