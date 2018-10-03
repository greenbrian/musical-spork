#!/usr/bin/env bash
set -x

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

echo "Installing jq"
sudo curl --silent -Lo /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64
sudo chmod +x /bin/jq

echo "Configuring Docker options and service"
sudo sh -c "echo \"DOCKER_OPTS='--dns 127.0.0.1 --dns 8.8.8.8 --dns-search service.consul'\" >> /etc/default/docker"

sudo systemctl enable docker
sudo systemctl start docker

echo "Configuring system time"
sudo timedatectl set-timezone UTC

echo "Update resolv.conf"
sudo sed -i '1i nameserver 127.0.0.1\n' /etc/resolv.conf

echo "Configuring DNSmasq"
sudo bash -c "cat >/etc/dnsmasq.d/10-consul" << EOF
server=/consul/127.0.0.1#8600
EOF

echo "Enable DNSmasq"
sudo systemctl enable dnsmasq

echo "Installing Consul, Consul-template, Nomad and Vault"
install_from_zip() {
  cd /tmp && {
    unzip -qq "${1}.zip"
    sudo mv "${1}" "/usr/local/bin/${1}"
    sudo chmod +x "/usr/local/bin/${1}"
    rm -rf "${1}.zip"
  }
}

echo "Configuring HashiCorp directories"
directory_setup() {
  # create and manage permissions on directories
  sudo mkdir -pm 0755 /etc/${1}.d /opt/${1}/data /opt/${1}/tls
  sudo chown -R ${1}:${1} /etc/${1}.d /opt/${1}/data /opt/${1}/tls
  sudo chmod -R 0644 /etc/${1}.d/*
}

install_from_zip consul
install_from_zip consul-template
install_from_zip nomad
install_from_zip vault
directory_setup consul
directory_setup consul-template
directory_setup nomad
directory_setup vault
directory_setup vault-agent


echo "Copy systemd services"
echo "Determine OS type"
if [[ ! -z ${YUM} ]]; then
  SYSTEMD_DIR="/etc/systemd/system"
elif [[ ! -z ${APT_GET} ]]; then
  echo "Debian/Ubuntu system detected"
  SYSTEMD_DIR="/lib/systemd/system"
else
  echo "OS detection failure"
  exit 1;
fi

systemd_files() {
  sudo cp /tmp/files/$1 $2
  sudo chmod 0664 $2/$1
}
systemd_files consul.service ${SYSTEMD_DIR}
systemd_files consul-template.service ${SYSTEMD_DIR}
systemd_files consul-online.service ${SYSTEMD_DIR}
systemd_files consul-online.target ${SYSTEMD_DIR}
systemd_files nomad.service ${SYSTEMD_DIR}
systemd_files vault.service ${SYSTEMD_DIR}
systemd_files vault-agent.service ${SYSTEMD_DIR}
systemd_files nomad-token-secure-intro.service ${SYSTEMD_DIR}

sudo cp /tmp/files/consul-online.sh /usr/bin/consul-online.sh
sudo chmod +x /usr/bin/consul-online.sh
sudo systemctl enable consul-online

sudo cp /tmp/files/aws-iam-login.sh /usr/bin/aws-iam-login.sh
sudo chmod +x /usr/bin/aws-iam-login.sh

sudo cp /tmp/files/aws-iam-login-cleanup.sh /usr/bin/aws-iam-login-cleanup.sh
sudo chmod +x /usr/bin/aws-iam-login-cleanup.sh

sudo cp /tmp/files/check_mem.sh /usr/bin/check_mem.sh
sudo chmod +x /usr/bin/check_mem.sh

sudo cp /tmp/files/check_cpu.sh /usr/bin/check_cpu.sh
sudo chmod +x /usr/bin/check_cpu.sh

sudo cp /tmp/files/vault_setup.sh /usr/bin/vault_setup.sh
sudo chmod +x /usr/bin/vault_setup.sh

echo "Setup Hashistack profile"
cat <<PROFILE | sudo tee /etc/profile.d/hashistack.sh
export CONSUL_ADDR=http://127.0.0.1:8500
export NOMAD_ADDR="http://nomad-server.service.consul:4646"
export VAULT_ADDR="http://active.vault.service.consul:8200"
#export VAULT_TOKEN=root
PROFILE

echo "Give consul user shell access for remote exec"
sudo /usr/sbin/usermod --shell /bin/bash consul >/dev/null

echo "Allow consul sudo access for echo, tee, cat, sed, and systemctl"
cat <<SUDOERS | sudo tee /etc/sudoers.d/consul
consul ALL=(ALL) NOPASSWD: /usr/bin/echo, /usr/bin/tee, /usr/bin/cat, /usr/bin/sed, /usr/bin/systemctl, /bin/systemctl
SUDOERS

echo "Setup ramdisk for Vault token sink"
mkdir /mnt/ramdisk
cat <<FSTAB | sudo tee /etc/fstab
tmpfs       /mnt/ramdisk tmpfs   nodev,nosuid,noexec,nodiratime,size=20M   0 0
FSTAB

