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
  description = "Minecraft szerver igényeket kiszolgáló virtuális számítógép eszköz debian operációs rendszerrel és crafty vezérlő masinável docker konténerizációs környezetben futtatva! usr: mc"
  tags        = ["debian", "minecraft", "terraform"]

  vm_id = 101

  agent {
    enabled = true
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 8192
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

    user_account {
      username = var.vm_username
      password = var.vm_password
      keys     = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]
    }

    ip_config {
      ipv4 {
        address = "10.1.1.3/24"
        gateway = "10.1.1.1"
      }
    }

    dns {
      servers = ["8.8.8.8", "1.1.1.1"]
    }
  }
}

resource "null_resource" "docker_setup_and_run" {

  depends_on = [proxmox_virtual_environment_vm.mc]

  triggers = {
    vm_id        = proxmox_virtual_environment_vm.mc.vm_id
    vm_username  = var.vm_username
    docker_setup = filesha256("${path.module}/../../scripts/docker.sh")
    compose      = filesha256("${path.module}/../../docker/crafty/docker-compose.yml")
    permissions  = "root-group-v1"
  }

  connection {
    type        = "ssh"
    host        = "10.1.1.3"
    user        = var.vm_username
    private_key = file(pathexpand("~/.ssh/id_ed25519"))
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "id -u mc >/dev/null 2>&1 || useradd -m -U -s /bin/bash mc",
      "install -d -o mc -g $(id -gn mc) -m 0750 /home/mc"
    ]
  }



  provisioner "file" {
    source      = "${path.module}/../../scripts/docker.sh"
    destination = "/home/mc/install-docker.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../docker/crafty/docker-compose.yml"
    destination = "/home/mc/docker-compose.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../../src/crafty.zip"
    destination = "/home/mc/crafty.zip"
  }

  provisioner "remote-exec" {
    inline = [
      "bash /home/mc/install-docker.sh",
      "apt install unzip -y",
      "chown mc:mc /home/mc/install-docker.sh /home/mc/docker-compose.yml /home/mc/crafty.zip",
      "runuser -u mc -- unzip -o /home/mc/crafty.zip -d /home/mc",
      "chgrp root /home/mc && chmod g+x /home/mc",
      "chgrp -R root /home/mc/crafty",
      "chmod -R g+rwX /home/mc/crafty",
      "find /home/mc/crafty -type d -exec chmod g+s {} +",
      "rm /home/mc/crafty.zip",
      "docker compose -f /home/mc/docker-compose.yml up -d"
    ]
  }


}
