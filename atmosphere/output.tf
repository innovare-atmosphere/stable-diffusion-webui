output "ip_address" {
  description = "IP Address of deployed server"
  value       = digitalocean_droplet.www-stable-diffusion-webui.ipv4_address
}

output "http_address" {
  description = "You can visit your installation at: "
  value       = "http://${var.domain != "" ? var.domain : digitalocean_droplet.www-stable-diffusion-webui.ipv4_address}/"
}