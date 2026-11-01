variable "proxmox_host" {
  description = "Proxmox API URL"
  type        = string
}
variable "proxmox_username" {
  type = string
}
variable "proxmox_password" {
  type      = string
  sensitive = true
}
variable "vm_username" {
  description = "SSH user with passwordless sudo in the Debian template"
  type        = string
}
variable "vm_password" {
  type      = string
  sensitive = true
}
variable "forgejo_vm_id" {
  type    = number
  default = 104
}
variable "runner_vm_id" {
  type    = number
  default = 105
}
variable "forgejo_address" {
  type    = string
  default = "10.1.1.5/24"
}
variable "runner_address" {
  type    = string
  default = "10.1.1.6/24"
}
variable "forgejo_domain" {
  description = "Forgejo hostname (without scheme or port)"
  type        = string
  default     = "10.1.1.5"
}
variable "forgejo_root_url" {
  description = "URL reachable by users and runner job containers"
  type        = string
  default     = "http://10.1.1.5:3000/"
}
