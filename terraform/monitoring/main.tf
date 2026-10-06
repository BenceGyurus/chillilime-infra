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
  tags        = ["debian", "monitoring", "terraform"]

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
    size         = 20
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
        address = "10.1.1.4/24"
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
    prometheus   = filesha256("${path.module}/../../config/prometheus/prometheus.yml")
    alerts       = filesha256("${path.module}/../../config/prometheus/alerts.yml")
    pve          = filesha256("${path.module}/../../config/prometheus/pve.yml")
    datasource   = filesha256("${path.module}/../../config/grafana/provisioning/datasources/prometheus.yml")
    dashboards   = filesha256("${path.module}/../../config/grafana/provisioning/dashboards/default.yml")
    overview     = filesha256("${path.module}/../../config/grafana/dashboards/overview.json")
    host         = split("/", proxmox_virtual_environment_vm.monitoring.initialization[0].ip_config[0].ipv4[0].address)[0]
    deployment   = "monitoring-v2"
  }

  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.monitoring]
  }

  connection {
    type        = "ssh"
    host        = self.triggers.host
    user        = var.vm_username
    private_key = file(pathexpand("~/.ssh/id_ed25519"))
    timeout     = "10m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -n install -d -o $(id -u) -g $(id -g) -m 0750 /home/monitoring /home/monitoring/prometheus /home/monitoring/pve-exporter",
      "if [ -f /home/monitoring/pve-exporter/pve.yml ]; then sudo -n chown $(id -u):$(id -g) /home/monitoring/pve-exporter/pve.yml; fi",
      "sudo -n install -d -o $(id -u) -g $(id -g) -m 0755 /home/monitoring/grafana/provisioning/datasources /home/monitoring/grafana/provisioning/dashboards /home/monitoring/grafana/dashboards"
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
    source      = "${path.module}/../../config/prometheus/prometheus.yml"
    destination = "/home/monitoring/prometheus/prometheus.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../../config/prometheus/pve.yml"
    destination = "/home/monitoring/pve-exporter/pve.yml"
  }


  provisioner "file" {
    source      = "${path.module}/../../config/prometheus/alerts.yml"
    destination = "/home/monitoring/prometheus/alerts.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../../config/grafana/provisioning/datasources/prometheus.yml"
    destination = "/home/monitoring/grafana/provisioning/datasources/prometheus.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../../config/grafana/provisioning/dashboards/default.yml"
    destination = "/home/monitoring/grafana/provisioning/dashboards/default.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../../config/grafana/dashboards/overview.json"
    destination = "/home/monitoring/grafana/dashboards/overview.json"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 0600 /home/monitoring/.env",
      "sudo -n chown 101:101 /home/monitoring/pve-exporter/pve.yml && sudo -n chmod 0600 /home/monitoring/pve-exporter/pve.yml",
      "chmod 0644 /home/monitoring/prometheus/*.yml /home/monitoring/grafana/provisioning/datasources/*.yml /home/monitoring/grafana/provisioning/dashboards/*.yml /home/monitoring/grafana/dashboards/*.json",
      "sudo -n bash /home/monitoring/install-docker.sh",
      "sudo -n apt-get install -y prometheus-node-exporter",
      "sudo -n systemctl enable --now prometheus-node-exporter",
      "sudo -n docker compose --env-file /home/monitoring/.env -f /home/monitoring/docker-compose.yml config --quiet",
      "sudo -n docker compose --env-file /home/monitoring/.env -f /home/monitoring/docker-compose.yml up -d --force-recreate"
    ]
  }
}
