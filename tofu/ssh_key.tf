# Generate a new SSH key pair when no public key is provided.
resource "tls_private_key" "generated" {
  count     = var.ssh_public_key_path == null ? 1 : 0
  algorithm = "ED25519"
}

# Store the generated private key locally.
resource "local_sensitive_file" "private_key" {
  count           = var.ssh_public_key_path == null ? 1 : 0
  filename        = "${path.module}/generated/id_ed25519"
  content         = tls_private_key.generated[0].private_key_openssh
  file_permission = "0600"
}

# Store the generated public key locally.
resource "local_file" "public_key" {
  count    = var.ssh_public_key_path == null ? 1 : 0
  filename = "${path.module}/generated/id_ed25519.pub"
  content  = tls_private_key.generated[0].public_key_openssh
}

locals {
  # Safe evaluation of external key file vs generated key
  ssh_public_key = var.ssh_public_key_path != null ? try(file(var.ssh_public_key_path), "") : tls_private_key.generated[0].public_key_openssh
}

# Upload the SSH public key to Hostinger.
resource "hostinger_vps_ssh_key" "main" {
  name = var.ssh_key_name
  key  = local.ssh_public_key
}