# Example configuration.
# Copy this file to terraform.tfvars and update the values.

ssh_public_keys = {
  ibrahim = "ssh-ed25519 AAAA... ibrahim@laptop"
}

k3s_role  = "server"
k3s_token = "CHANGE_ME"
ssh_port  = 15022

vps_instances = {
  web-01 = {
    hostname       = "web-01.example.com"
    plan           = "kvm2"
    template_id    = 1007
    data_center_id = 14
  }
}