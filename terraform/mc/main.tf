terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">=0.60.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">=3.0.0"
    }
  }
}


provider "proxmox" {
  endpoint = var.proxmox_host
  username = var.proxmox_username
  password = var.proxmox_password
  insecure = true
}



resource "proxmox_virtual_environment_vm" "mc" {
  node_name   = "chililime"
  name        = "mc-kiszolgalo"
  started     = true
  description = "Minecraft szerver igényeket kiszolgáló virtuális számítógép eszköz debian operációs rendszerrel és crafty vezérlő masinável docker konténerizációs környezetben futtatva!"
  tags        = ["debian", "minecraft", "terraform"]

  vm_id = 101

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  clone {
    vm_id     = 100
    node_name = "chililime"
    full      = true
  }

  disk {
    datastore_id = "vm-disk1"
    interface    = "scsi0"
    size         = 30
  }

  network_device {
    bridge = "vmbr1"
    model  = "virtio"
  }

  initialization {
    datastore_id = "vm-disk1"

    ip_config {
      ipv4 {
        address = "10.1.1.3/24"
        gateway = "10.1.1.1"
      }
    }

    dns {
        servers = ["8.8.8.8","1.1.1.1"]
    }
  }
}

resource "null_resource" "docker_setup_and_run" {

  depends_on = [proxmox_virtual_environment_vm.mc]

  connection {
    type        = "ssh"
    host        = "10.1.1.3"
    user        = "root"
    private_key = file(pathexpand("~/.ssh/id_ed25519"))
    timeout     = "2m"
  }



  provisioner "file" {
    source      = "${path.module}/../../scripts/docker.sh"
    destination = "/root/install-docker.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../docker/crafty/docker-compose.yml"
    destination = "/root/docker-compose.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../../src/crafty.zip"
    destination = "/root/crafty.zip"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /root/install-docker.sh",
      "apt install unzip -y",
      "unzip -o /root/crafty.zip -d /root",
      "docker compose -f /root/docker-compose.yml up -d"
    ]
  }


}
