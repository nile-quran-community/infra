resource "hostinger_vps_ssh_key" "main" {
  for_each = var.ssh_public_keys

  name = each.key
  key  = each.value
}

resource "hostinger_vps_post_install_script" "k3s_setup" {
  name = "k3s-bootstrap-and-hardening"

  content = templatefile("${path.module}/templates/k3s-bootstrap.sh.tpl", {
    k3s_version    = var.k3s_version
    k3s_role       = var.k3s_role
    k3s_token      = coalesce(var.k3s_token, "")
    k3s_server_url = var.k3s_server_url
    ssh_port       = var.ssh_port
  })
}

resource "hostinger_vps" "server" {
  for_each = var.vps_instances

  hostname       = each.value.hostname
  plan           = each.value.plan
  template_id    = each.value.template_id
  data_center_id = each.value.data_center_id

  ssh_key_ids = [for k in hostinger_vps_ssh_key.main : k.id]

  post_install_script_id = hostinger_vps_post_install_script.k3s_setup.id
}