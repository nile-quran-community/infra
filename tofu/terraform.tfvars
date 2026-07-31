ssh_public_keys = {
  youssef = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEG7TxHMftZu28W+f/GSUTrGjo/WRU79XmgzpVPgQpyi"
}

k3s_role = "server"
ssh_port = 15022

vps_instances = {
  k3s-server = {
    hostname       = "k3s-server.nuqc.local"
    plan           = "hostingereg-vps-kvm2-egp-1m"
    template_id    = 1077 # NOTE: Ubuntu 24.04 LTS
    data_center_id = 19   # NOTE: Frankfurt
  }
}
