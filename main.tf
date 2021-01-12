variable "image" {
  default = "ubuntu-20-04-x64"
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# SSH key
resource "digitalocean_ssh_key" "terraform" {
  name       = "Terraform SSH Key"
  public_key = file(pathexpand("${path.module}/private-keys/terraform.pub"))
}


# US server
resource "digitalocean_droplet" "us_server" {
  image    = var.image
  name     = "us001.app.r2pi.com"
  region   = "nyc3"
  size     = "s-1vcpu-2gb"
  ipv6     = true
  ssh_keys = [digitalocean_ssh_key.terraform.fingerprint]

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(pathexpand("${path.module}/private-keys/terraform.pem"))
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get -yyq update && apt-get -yyq install nginx && echo '<h1>My Awesome App</h1><br/><pre>served from US server</pre>' >/var/www/html/index.html"
    ]
  }
}

# EU server
resource "digitalocean_droplet" "eu_server" {
  image    = var.image
  name     = "eu001.app.r2pi.com"
  region   = "fra1"
  size     = "s-1vcpu-2gb"
  ipv6     = true
  ssh_keys = [digitalocean_ssh_key.terraform.fingerprint]

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(pathexpand("${path.module}/private-keys/terraform.pem"))
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get -yyq update && apt-get -yyq install nginx && echo '<h1>My Awesome App</h1><br/><pre>served from EU server</pre>' >/var/www/html/index.html"
    ]
  }
}

# AP server
resource "digitalocean_droplet" "ap_server" {
  image    = var.image
  name     = "ap001.app.r2pi.com"
  region   = "sgp1"
  size     = "s-1vcpu-2gb"
  ipv6     = true
  ssh_keys = [digitalocean_ssh_key.terraform.fingerprint]

  connection {
    host        = self.ipv4_address
    type        = "ssh"
    user        = "root"
    private_key = file(pathexpand("${path.module}/private-keys/terraform.pem"))
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get -yyq update && apt-get -yyq install nginx && echo '<h1>My Awesome App</h1><br/><pre>served from AP server</pre>' >/var/www/html/index.html"
    ]
  }
}




# Configure the NS1 provider
provider "ns1" {
  apikey = var.ns1_apikey
}

resource "ns1_zone" "r2pi" {
  zone = "app.r2pi.com"
  ttl  = 600
}

resource "ns1_record" "app" {
  zone   = ns1_zone.r2pi.zone
  domain = ns1_zone.r2pi.zone
  type   = "A"
  ttl    = 10

  answers {
    answer    = digitalocean_droplet.us_server.ipv4_address
    meta      = {
      up      = true
      country = "US"
    }
  }

  answers {
    answer    = digitalocean_droplet.eu_server.ipv4_address
    meta      = {
      up      = true
      country = "DE"
    }
  }

  answers {
    answer    = digitalocean_droplet.ap_server.ipv4_address
    meta      = {
      up      = true
      country = "SG"
    }
  }

  filters {
    filter = "up"
  }

  filters {
    filter = "geotarget_country"
  }

  filters {
    filter = "select_first_n"

    config = {
      N = 1
    }
  }
}
