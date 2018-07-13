#!/usr/bin/env bash
set -x

echo "Performing updates and installing prerequisites"
sudo yum-config-manager --enable rhui-REGION-rhel-server-releases-optional
sudo yum-config-manager --enable rhui-REGION-rhel-server-supplementary
sudo yum-config-manager --enable rhui-REGION-rhel-server-extras
sudo yum -y check-update
sudo yum install -q -y wget unzip dnsmasq bind-utils ruby rubygems ntp git ca-certificates vim-enhanced
sudo systemctl start ntpd.service
sudo systemctl enable ntpd.service
sudo systemctl stop firewalld.service
sudo systemctl disable firewalld.service
curl --silent -O https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py
sudo pip install awscli
echo "Adding Consul and Vault system users"
  # RHEL user setup
for _user in consul consul-template vault; do
  sudo /usr/sbin/groupadd --force --system ${_user}
  if ! getent passwd ${_user} >/dev/null ; then
    sudo /usr/sbin/adduser \
      --system \
      --gid ${_user} \
      --home /srv/${_user} \
      --no-create-home \
      --comment "${_user} account" \
      --shell /bin/false \
      ${_user}  >/dev/null
  fi
done