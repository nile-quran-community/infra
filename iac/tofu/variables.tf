variable "hostinger_api_token" {
  description = "Hostinger API token"
  type        = string
  sensitive   = true
}

variable "ssh_public_keys" {
  description = "Map of key name => SSH public key content. All keys are attached to every VPS."
  type        = map(string)
}

variable "ssh_port" {
  description = "Non-default SSH port"
  type        = number
  default     = 15022
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
