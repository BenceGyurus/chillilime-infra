resource "null_resource" "forgejo_setup" {
  triggers = {
    host               = split("/", proxmox_virtual_environment_vm.forgejo.initialization[0].ip_config[0].ipv4[0].address)[0]
    vm_username        = var.vm_username
    docker_sh          = filesha256("${path.module}/../../scripts/docker.sh")
    docker_compose_yml = filesha256("${path.module}/../../docker/forgejo/docker-compose.yml")
    env                = filesha256("${path.module}/../../docker/forgejo/.env")
    storage_sh         = filesha256("${path.module}/../../scripts/forgejo-storage.sh")
    domain             = var.forgejo_domain
    root_url           = var.forgejo_root_url
  }
  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.forgejo]
  }
  connection {
    type        = "ssh"
    host        = self.triggers.host
    user        = var.vm_username
    private_key = file(pathexpand("~/.ssh/id_ed25519"))
    timeout     = "10m"
  }
  provisioner "remote-exec" {
    inline = ["sudo -n install -d -o $(id -u) -g $(id -g) -m 0750 /opt/forgejo"]
  }
  provisioner "file" {
    source      = "${path.module}/../../scripts/docker.sh"
    destination = "/opt/forgejo/docker.sh"
  }
  provisioner "file" {
    source      = "${path.module}/../../docker/forgejo/docker-compose.yml"
    destination = "/opt/forgejo/docker-compose.yml"
  }
  provisioner "file" {
    source      = "${path.module}/../../docker/forgejo/.env"
    destination = "/opt/forgejo/.env"
  }
  provisioner "file" {
    source      = "${path.module}/../../scripts/forgejo-storage.sh"
    destination = "/opt/forgejo/storage.sh"
  }
  provisioner "file" {
    content = yamlencode({
      services = {
        forgejo = {
          environment = {
            FORGEJO__server__DOMAIN     = "$${FORGEJO_DOMAIN:-${var.forgejo_domain}}"
            FORGEJO__server__SSH_DOMAIN = "$${FORGEJO_DOMAIN:-${var.forgejo_domain}}"
            FORGEJO__server__ROOT_URL   = "$${FORGEJO_ROOT_URL:-${var.forgejo_root_url}}"
          }
        }
      }
    })
    destination = "/opt/forgejo/compose.override.yml"
  }
  provisioner "remote-exec" {
    inline = [
      "set -eu",
      "chmod 0600 /opt/forgejo/.env",
      "sudo -n cloud-init status --wait --format json > /tmp/chillilime-cloud-init-status.json || test $? -eq 2",
      "python3 -c 'import json; s=json.load(open(\"/tmp/chillilime-cloud-init-status.json\")); assert s[\"status\"] == \"done\" and not s[\"errors\"] and set(s.get(\"recoverable_errors\", {})) <= {\"DEPRECATED\"}, s'",
      "sudo -n bash -e /opt/forgejo/docker.sh",
      "sudo -n apt-get install -y e2fsprogs util-linux",
      "sudo -n bash /opt/forgejo/storage.sh",
      "sudo -n apt-get install -y prometheus-node-exporter",
      "sudo -n systemctl enable --now prometheus-node-exporter",
      "sudo -n docker compose --env-file /opt/forgejo/.env -f /opt/forgejo/docker-compose.yml -f /opt/forgejo/compose.override.yml config --quiet",
      "sudo -n docker compose --env-file /opt/forgejo/.env -f /opt/forgejo/docker-compose.yml -f /opt/forgejo/compose.override.yml up -d"
    ]
  }
}
