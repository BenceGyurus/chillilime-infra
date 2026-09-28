variable "proxmox_username" {
  description = "Proxmox username"
  type        = string
}

# változó létrehozása a jelszónak

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

# változó a proxmox IP-jéhez

variable "proxmox_host" {
  description = "Proxmox host URL"
  type        = string
}
