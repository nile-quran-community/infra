terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket = "nu-quran-community-terraform"
    key    = "nuqc-production"
    region = "eu-west-1"
  }
}
