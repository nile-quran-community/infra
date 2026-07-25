resource "hostinger_vps" "server" {
  for_each = var.vps_instances

  hostname       = each.value.hostname
  plan           = each.value.plan
  template_id    = each.value.template_id
  data_center_id = each.value.data_center_id

  # Attach every configured SSH key to every VPS.
  ssh_key_ids = [for k in hostinger_vps_ssh_key.main : k.id]

  post_install_script_id = hostinger_vps_post_install_script.k3s_setup.id
}