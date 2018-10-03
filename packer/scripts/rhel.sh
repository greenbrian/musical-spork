#!/usr/bin/env bash
set -x

echo "Performing updates and installing prerequisites"
sudo yum-config-manager --enable rhui-REGION-rhel-server-releases-optional
sudo yum-config-manager --enable rhui-REGION-rhel-server-supplementary
sudo yum-config-manager --enable rhui-REGION-rhel-server-extras
sudo yum -y check-update
sudo rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
sudo yum install -q -y wget unzip dnsmasq bind-utils ruby rubygems \
  ntp git ca-certificates vim-enhanced haproxy nginx
sudo systemctl start ntpd.service
sudo systemctl enable ntpd.service
sudo systemctl stop firewalld.service
sudo systemctl disable firewalld.service
curl --silent -O https://bootstrap.pypa.io/get-pip.py
sudo python get-pip.py
sudo pip install awscli
echo "Adding Consul and Vault system users"
  # RHEL user setup
for _user in consul consul-template vault vault-agent; do
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

echo "Installing Docker with RHEL Workaround"
sudo yum -yq install policycoreutils-python yum-utils device-mapper-persistent-data lvm2
sudo yum -y remove docker docker-client docker-client-latest docker-common docker-latest \
  docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux \
  docker-engine container-selinux
sudo yum-config-manager -y --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y --setopt=obsoletes=0 \
  docker-ce-18.06.1.ce-3.el7.x86_64
