# Authenticate all Hostinger resources using the provided API token.

provider "hostinger" {
  api_token = var.hostinger_api_token
}