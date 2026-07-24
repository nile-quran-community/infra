# Run a bootstrap script immediately after VPS provisioning.
resource "hostinger_vps_post_install_script" "docker_setup" {
  count = var.install_docker ? 1 : 0

  name = "docker-and-hardening-setup"

  content = <<-SCRIPT
#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get upgrade -y

curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
rm -f /tmp/get-docker.sh

apt-get install -y docker-compose-plugin

systemctl enable docker
systemctl start docker

sed -i 's/^#\\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#\\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config

systemctl restart sshd || systemctl restart ssh

if command -v ufw >/dev/null 2>&1; then
  ufw allow OpenSSH
  ufw allow 80/tcp
  ufw allow 443/tcp
  ufw --force enable
fi
SCRIPT
}