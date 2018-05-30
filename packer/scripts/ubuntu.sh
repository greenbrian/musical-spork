#!/usr/bin/env bash
set -x

echo "Debian/Ubuntu system detected"
SYSTEMD_DIR="/lib/systemd/system"
echo "Performing updates and installing prerequisites"

function ssh-apt {
  sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq \
    --allow-downgrades \
    --allow-remove-essential \
    --allow-change-held-packages \
    -o Dpkg::Use-Pty=0 \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    "$@"
}

sudo apt-get -qq -y update
ssh-apt install wget unzip dnsutils ruby rubygems ntp git dnsmasq-base dnsmasq default-jdk awscli telnet vim
sudo systemctl start ntp.service
sudo systemctl enable ntp.service
echo "Disable reverse dns lookup in SSH"
sudo sh -c 'echo "\nUseDNS no" >> /etc/ssh/sshd_config'
sudo service ssh restart
sudo ufw disable
echo "Adding Consul and Vault system users"
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
echo "Installing Docker for Nomad"
curl -sSL https://get.docker.com/ | sudo sh