# No key generation. Every key must already exist and be passed in via
# ssh_public_keys — one hostinger_vps_ssh_key resource per entry.
resource "hostinger_vps_ssh_key" "main" {
  for_each = var.ssh_public_keys

  name = each.key
  key  = each.value
}