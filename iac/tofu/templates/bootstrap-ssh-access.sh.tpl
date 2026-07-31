#!/usr/bin/env bash
set -euo pipefail

apt-get update -y
apt-get upgrade -y

sed -i 's/^#\?Port .*/Port ${ssh_port}/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
systemctl restart sshd || systemctl restart ssh
