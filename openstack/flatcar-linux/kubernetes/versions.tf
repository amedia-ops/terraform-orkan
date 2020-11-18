# Terraform version and plugin versions

terraform {
  required_version = ">= 0.13"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.24"
    }
    template = {
      source  = "hashicorp/template"
      version = "~> 2.1"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 2.1"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "~> 2.2"
    }

    ct = {
      source  = "poseidon/ct"
      version = "~> 0.6.1"
    }
  }
}
