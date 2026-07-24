# Example configuration.
# Copy this file to terraform.tfvars and update the values.

ssh_key_name   = "terraform-key"
install_docker = true

vps_instances = {
  web-01 = {
    hostname       = "web-01.example.com"
    plan           = "kvm2"
    template_id    = 1002
    data_center_id = 13
  }
}