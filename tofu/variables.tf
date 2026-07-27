variable "hostinger_api_token" {
  description = "Hostinger API token"
  type        = string
  sensitive   = true
  default     = null
}

# Map of key name => raw public key content. No file paths, no generation.
variable "ssh_public_keys" {
  description = "Map of key name => SSH public key content. All keys are attached to every VPS."
  type        = map(string)
}

# Non-default SSH port, hardened in the post-install script below.
variable "ssh_port" {
  description = "Non-default SSH port"
  type        = number
  default     = 15022
}

# "server" = first/control node that starts the cluster.
# "agent"  = joins an existing cluster, needs k3s_server_url.
variable "k3s_role" {
  description = "k3s node role: server or agent"
  type        = string
  default     = "server"

  validation {
    condition     = contains(["server", "agent"], var.k3s_role)
    error_message = "k3s_role must be \"server\" or \"agent\"."
  }
}

variable "k3s_version" {
  description = "k3s channel/version, e.g. v1.30.2+k3s1. Empty = latest stable."
  type        = string
  default     = ""
}

variable "k3s_token" {
  description = "Cluster join token. Optional — if omitted, k3s generates one automatically."
  type        = string
  sensitive   = true
  default     = null
}

variable "k3s_server_url" {
  description = "Existing k3s server URL, e.g. https://10.0.0.1:6443. Required when k3s_role = \"agent\"."
  type        = string
  default     = null
}

variable "vps_instances" {
  description = "Map of servers to create. Key = logical name, value = its config."
  type = map(object({
    hostname       = string
    plan           = string
    template_id    = number
    data_center_id = number
  }))
}