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



resource "proxmox_virtual_environment_vm" "monitoring" {
  node_name   = "chililime"
  name        = "monitoring"
  started     = true
  description = "Egy olyan kiszolgáló eszköz ahol lehet látni, hogy mi a hézag és Gyugyu mennyire használja az mc szerót amit annyira szerett volna"
  tags        = ["debian", "minecraft", "terraform"]

  vm_id = 103

  agent {
    enabled = true
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 2048
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

  depends_on = [proxmox_virtual_environment_vm.monitoring]

  triggers = {
    vm_id        = proxmox_virtual_environment_vm.monitoring.vm_id
    vm_username  = var.vm_username
    docker_setup = filesha256("${path.module}/../../scripts/docker.sh")
    compose      = filesha256("${path.module}/../../docker/monitoring/docker-compose.yml")
    env          = filesha256("${path.module}/../../docker/monitoring/.env")
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
      "id -u monitoring >/dev/null 2>&1 || useradd -m -U -s /bin/bash monitoring",
      "install -d -o monitoring -g $(id -gn monitoring) -m 0750 /home/monitoring"
    ]
  }



  provisioner "file" {
    source      = "${path.module}/../../scripts/docker.sh"
    destination = "/home/monitoring/install-docker.sh"
  }


  provisioner "file" {
    source      = "${path.module}/../../docker/monitoring/docker-compose.yml"
    destination = "/home/monitoring/docker-compose.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../../docker/monitoring/.env"
    destination = "/home/monitoring/.env"
  }


  provisioner "file" {
    source      = "${path.module}/../../config/prometheus.yml"
    destination = "/home/monitoring/prometheus.yml"
  }


  provisioner "remote-exec" {
    inline = [
      "bash /home/monitoring/install-docker.sh",
      "apt install unzip -y",
      "chgrp root /home/monitoring && chmod g+x /home/monitoring",
      "chgrp -R root /home/monitoring/monitoring",
      "chmod -R g+rwX /home/monitoring/monitoring",
      "find /home/monitoring/monitoring -type d -exec chmod g+s {} +",
      "docker compose -f /home/monitoring/docker-compose.yml up -d"
    ]
  }


}
