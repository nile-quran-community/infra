#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get upgrade -y

export INSTALL_K3S_VERSION="${k3s_version}"

%{ if k3s_role == "server" }
curl -sfL https://get.k3s.io | %{ if k3s_token != "" }K3S_TOKEN="${k3s_token}"%{ endif } sh -s - server
%{ else }
curl -sfL https://get.k3s.io | K3S_URL="${k3s_server_url}" %{ if k3s_token != "" }K3S_TOKEN="${k3s_token}"%{ endif } sh -s - agent
%{ endif }

sed -i 's/^#\?Port .*/Port ${ssh_port}/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart sshd || systemctl restart ssh

if command -v ufw >/dev/null 2>&1; then
  ufw allow "${ssh_port}/tcp"
  ufw allow 6443/tcp
  ufw allow 8472/udp
  ufw allow 10250/tcp
  ufw allow 80/tcp
  ufw allow 443/tcp
  %{ if k3s_role == "server" ~}
  ufw allow 2379/tcp
  ufw allow 2380/tcp
  %{ endif ~}
  ufw --force enable
fi
