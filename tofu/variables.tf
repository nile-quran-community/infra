# Hostinger API token.
# Prefer passing it through TF_VAR_hostinger_api_token.
variable "hostinger_api_token" {
  description = "Hostinger API token"
  type        = string
  sensitive   = true
  default     = null
}

# Existing SSH public key path.
# Leave null to generate a new key pair automatically.
variable "ssh_public_key_path" {
  description = "Path to an existing SSH public key"
  type        = string
  default     = null
}

# Display name for the uploaded SSH key.
variable "ssh_key_name" {
  description = "SSH key name"
  type        = string
  default     = "terraform-managed-key"
}

# Enable Docker installation after VPS provisioning.
variable "install_docker" {
  description = "Install Docker automatically"
  type        = bool
  default     = true
}

# VPS instances to provision.
variable "vps_instances" {
  description = "Map of VPS instances"

  type = map(object({
    hostname       = string
    plan           = string
    template_id    = number
    data_center_id = number
  }))
}