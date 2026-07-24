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

output "ssh_key_id" {
  description = "Hostinger SSH key ID"
  value       = hostinger_vps_ssh_key.main.id
}

output "ssh_private_key_path" {
  description = "Local path to the private key (only if auto-generated)"
  value       = var.ssh_public_key_path == null ? local_sensitive_file.private_key[0].filename : "Using existing key: ${var.ssh_public_key_path}"
}

output "backup_passwords" {
  description = "Backup random passwords per server (sensitive)"
  value = {
    for key, pw in random_password.vps : key => pw.result
  }
  sensitive = true
}