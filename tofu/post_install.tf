# Bootstraps k3s (server or agent) and hardens SSH.
# NOTE: k3s_token is interpolated into this script and stored in state as
# plain text — keep the backend private once a real token is used.
resource "hostinger_vps_post_install_script" "k3s_setup" {
  name    = "k3s-bootstrap-and-hardening"
  content = <<-SCRIPT
    #!/bin/bash
    set -euo pipefail

    apt-get update -y
    apt-get upgrade -y

    export INSTALL_K3S_VERSION="${var.k3s_version}"

    # Pick server vs agent install at render time based on k3s_role.
    %{if var.k3s_role == "server"}
    curl -sfL https://get.k3s.io | K3S_TOKEN="${var.k3s_token}" sh -s - server
    %{else}
    curl -sfL https://get.k3s.io | K3S_URL="${var.k3s_server_url}" K3S_TOKEN="${var.k3s_token}" sh -s - agent
    %{endif}

    # SSH hardening: custom port, key-only login.
    sed -i 's/^#\?Port .*/Port ${var.ssh_port}/' /etc/ssh/sshd_config
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
    systemctl restart sshd || systemctl restart ssh

    # Firewall: SSH on the custom port, plus k8s API and web ports.
    if command -v ufw >/dev/null 2>&1; then
      ufw allow ${var.ssh_port}/tcp
      ufw allow 6443/tcp
      ufw allow 80/tcp
      ufw allow 443/tcp
      ufw --force enable
    fi
  SCRIPT
}