resource "hostinger_vps_ssh_key" "main" {
  for_each = var.ssh_public_keys

  name = each.key
  key  = each.value
}


resource "hostinger_vps" "server" {
  for_each = var.vps_instances

  plan           = each.value.plan
  hostname       = each.value.hostname
  template_id    = each.value.template_id
  data_center_id = each.value.data_center_id
  ssh_key_ids    = [for k in hostinger_vps_ssh_key.main : k.id]
}
