terraform {
  required_version = ">= 1.2.0"
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



resource "proxmox_virtual_environment_container" "loadbalancer" {
  node_name     = "chililime"
  unprivileged  = true
  started       = true
  start_on_boot = true

  operating_system {
    template_file_id = var.container_template
    type             = "debian"
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 256
  }

  disk {
    datastore_id = "vm-disk1"
    size         = 4
  }

  initialization {
    hostname = "loadbalancer"

    dns {
      servers = ["8.8.8.8", "1.1.1.1"]
    }

    user_account {
      password = var.vm_password
      keys     = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub"))), trimspace(var.denes_public_key)]
    }

    ip_config {
      ipv4 {
        address = "10.1.1.254/24"
        gateway = "10.1.1.1"
      }
    }
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr1"
  }

}


resource "null_resource" "traefik_setup" {

  triggers = {
    config     = filesha256("${path.module}/../../config/traefik/traefik.yml")
    services   = filesha256("${path.module}/../../config/traefik/services.yml")
    deployment = "traefik-config-v3"
    installer  = filesha256("${path.module}/../../scripts/traefik.sh")
    mc_config  = filesha256("${path.module}/../../config/traefik/mc.yml")
    host       = split("/", proxmox_virtual_environment_container.loadbalancer.initialization[0].ip_config[0].ipv4[0].address)[0]
  }

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_container.loadbalancer]
  }

  connection {
    type        = "ssh"
    host        = self.triggers.host
    user        = var.vm_username
    private_key = file(pathexpand("~/.ssh/id_ed25519"))
    timeout     = "10m"
  }

  provisioner "file" {
    source      = "${path.module}/../../scripts/traefik.sh"
    destination = "/tmp/install-traefik.sh"
  }

  provisioner "file" {
    source      = "${path.module}/../../config/traefik/traefik.yml"
    destination = "/tmp/chillilime-traefik.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../../config/traefik/mc.yml"
    destination = "/tmp/chillilime-traefik-mc.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../../config/traefik/services.yml"
    destination = "/tmp/chillilime-traefik-services.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -n install -d -m 0755 /etc/traefik/dynamic",
      "sudo -n install -m 0644 /tmp/chillilime-traefik.yml /etc/traefik/traefik.yml",
      "sudo -n install -m 0644 /tmp/chillilime-traefik-mc.yml /etc/traefik/dynamic/mc.yml",
      "sudo -n install -m 0644 /tmp/chillilime-traefik-services.yml /etc/traefik/dynamic/services.yml",
      "sudo -n touch /etc/traefik/acme.json",
      "sudo -n bash /tmp/install-traefik.sh",
      "sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y prometheus-node-exporter",
      "sudo -n systemctl enable --now prometheus-node-exporter",
      "rm -f /tmp/install-traefik.sh /tmp/chillilime-traefik.yml /tmp/chillilime-traefik-mc.yml /tmp/chillilime-traefik-services.yml"
    ]
  }


}
