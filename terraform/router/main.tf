resource "opnsense_interfaces_vlan" "vlan" {
  description = "proxmox"
  tag = 10
  priority = 0
  parent = "vtnet0"
}