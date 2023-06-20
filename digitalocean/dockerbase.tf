variable "profile" {
    default = ""
}

variable "domain" {
    default = ""
    validation {
      # regex(...) fails if it cannot find a match
      condition     = can(regex("[0-9]*[a-z]+[a-z0-9]*", var.domain))
      error_message = "Domain name can only contain letters and numbers."
    }
}

variable "webmaster_email" {
    default = ""
}


resource "digitalocean_droplet" "www-stable-diffusion-webui" {
  #This has pre installed docker
  image = "docker-20-04"
  name = "www-stable-diffusion-webui"
  region = "nyc3"
  size = "s-8vcpu-16gb"
  ssh_keys = [
    digitalocean_ssh_key.terraform.id
  ]

  connection {
    host = self.ipv4_address
    user = "root"
    type = "ssh"
    private_key = var.pvt_key != "" ? file(var.pvt_key) : tls_private_key.pk.private_key_pem
    timeout = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # install nginx and docker
      "sleep 5s",
      "apt update",
      "sleep 5s",
      "apt install -y nginx",
      "apt install -y python3-certbot-nginx",
      "apt install -y git",
      # create stable-diffusion-webui installation directory
      "mkdir /root/stable-diffusion-webui-docker",
    ]
  }


  provisioner "file" {
    content      = templatefile("atmosphere-nginx.conf.tpl", {
      server_name = var.domain != "" ? var.domain : "0.0.0.0"
    })
    destination = "/etc/nginx/conf.d/atmosphere-nginx.conf"
  }

  provisioner "remote-exec" {
    inline = [
      "export PATH=$PATH:/usr/bin",
      # run compose
      "cd /root/stable-diffusion-webui-docker",
      "git clone https://github.com/AbdBarho/stable-diffusion-webui-docker.git",
      "cd /root/stable-diffusion-webui-docker/stable-diffusion-webui-docker",
      "docker compose --profile download up --build",
      "docker compose --profile auto-cpu up --build",
      "rm /etc/nginx/sites-enabled/default",
      "systemctl restart nginx",
      "ufw allow http",
      "ufw allow https",
      "%{if var.domain!= ""}certbot --nginx --non-interactive --agree-tos --domains ${var.domain} --redirect %{if var.webmaster_email!= ""} --email ${var.webmaster_email} %{ else } --register-unsafely-without-email %{ endif } %{ else }echo NOCERTBOT%{ endif }"
    ]
  }
}