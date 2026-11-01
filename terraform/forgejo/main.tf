terraform {
  required_version = ">= 1.2.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.60.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_host
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = true
}

resource "proxmox_virtual_environment_vm" "forgejo" {
  node_name   = "chililime"
  name        = "forgejo"
  description = "Forgejo: 15 GiB OS + 50 GiB mirrored data"
  vm_id       = var.forgejo_vm_id
  started     = true
  on_boot     = true
  tags        = ["debian", "forgejo", "terraform"]

  agent {
    enabled = true
  }
  cpu {
    cores = 2
  }
  memory {
    dedicated = 2048
  }
  clone {
    vm_id        = 100
    node_name    = "chililime"
    datastore_id = "vm-disk1"
    full         = true
  }
  disk {
    datastore_id = "vm-disk1"
    interface    = "scsi0"
    size         = 15
  }
  disk {
    datastore_id = "storage-mirror"
    interface    = "scsi1"
    serial       = "forgejo-data"
    size         = 50
    backup       = true
  }

  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }
  initialization {
    datastore_id = "vm-disk1"
    user_account {
      username = var.vm_username
      password = var.vm_password
      keys     = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]
    }
    ip_config {
      ipv4 {
        address = var.forgejo_address
        gateway = "10.1.1.1"
      }
    }
    dns {
      servers = ["8.8.8.8", "1.1.1.1"]
    }
  }
}

resource "proxmox_virtual_environment_vm" "runner" {
  node_name   = "chililime"
  name        = "forgejo-runner"
  description = "Forgejo Actions runner: Debian, 80 GiB OS and build data"
  vm_id       = var.runner_vm_id
  started     = true
  on_boot     = true
  tags        = ["debian", "forgejo", "terraform"]

  agent {
    enabled = true
  }
  cpu {
    cores = 10
    type  = "host"
  }
  memory {
    dedicated = 16384
  }
  clone {
    vm_id        = 100
    node_name    = "chililime"
    datastore_id = "vm-disk1"
    full         = true
  }
  disk {
    datastore_id = "vm-disk1"
    interface    = "scsi0"
    size         = 80
  }

  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }
  initialization {
    datastore_id = "vm-disk1"
    user_account {
      username = var.vm_username
      password = var.vm_password
      keys     = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]
    }
    ip_config {
      ipv4 {
        address = var.runner_address
        gateway = "10.1.1.1"
      }
    }
    dns {
      servers = ["8.8.8.8", "1.1.1.1"]
    }
  }
}
