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

variable "vm_username" {
  description = "LXC provisioning user; the template's SSH keys belong to root"
  type        = string
  default     = "root"

  validation {
    condition     = var.vm_username == "root"
    error_message = "LXC provisioning requires root; no other user is created by this module."
  }
}

variable "container_template" {
  description = "Existing Debian LXC template volume ID on the Proxmox node"
  type        = string
  default     = "local:vztmpl/debian-13-standard_13.6-1_amd64.tar.zst"
}


variable "vm_password" {
  description = "VM password"
  type        = string
  sensitive   = true
}


variable "denes_public_key" {
  description = "Dénesnek a windowsos publikus kulcsa a biztonságos héjához"
  type        = string
  sensitive   = true
}
