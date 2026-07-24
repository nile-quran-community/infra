# Configure the required OpenTofu version and provider dependencies.

terraform {
  required_version = ">= 1.6"

  required_providers {
    hostinger = {
      source  = "hostinger/hostinger"
      version = "~> 0.1.22"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}