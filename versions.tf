terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }
    ns1 = {
      source = "ns1-terraform/ns1"
    }
  }
  required_version = ">= 0.13"
}
