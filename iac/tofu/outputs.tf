output "servers" {
  description = "IP, ID, and status per server"
  value = {
    for key, vps in hostinger_vps.server : key => {
      id       = vps.id
      hostname = vps.hostname
      ipv4     = vps.ipv4_address
      status   = vps.status
    }
  }
}

output "ssh_key_ids" {
  description = "Hostinger key ID per configured SSH key name"
  value       = { for name, key in hostinger_vps_ssh_key.main : name => key.id }
}