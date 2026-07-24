# Generate a backup password for each VPS.
# This can be used if password authentication is required.
resource "random_password" "vps" {
  for_each = var.vps_instances

  length           = 20
  special          = true
  override_special = "!@#%^*()-_=+"
}

# Create one VPS for each entry in vps_instances.
resource "hostinger_vps" "server" {
  for_each = var.vps_instances

  hostname       = each.value.hostname
  plan           = each.value.plan
  template_id    = each.value.template_id
  data_center_id = each.value.data_center_id

  # Configure SSH access using the uploaded key.
  ssh_key_ids = [
    hostinger_vps_ssh_key.main.id
  ]

  # Uncomment if the provider requires a password.
  # password = random_password.vps[each.key].result

  # Run the bootstrap script after provisioning.
  post_install_script_id = var.install_docker ? hostinger_vps_post_install_script.docker_setup[0].id : null
}