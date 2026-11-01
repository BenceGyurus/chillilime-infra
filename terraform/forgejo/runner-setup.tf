resource "null_resource" "runner_setup" {
  triggers = {
    host               = split("/", proxmox_virtual_environment_vm.runner.initialization[0].ip_config[0].ipv4[0].address)[0]
    vm_username        = var.vm_username
    docker_sh          = filesha256("${path.module}/../../scripts/docker.sh")
    docker_compose_yml = filesha256("${path.module}/../../docker/forgejo-runner/docker-compose.yml")
    drain_script       = filesha256("${path.module}/../../scripts/forgejo-runner-drain.py")
    config_merge_py    = filesha256("${path.module}/../../scripts/forgejo-runner-config.py")
    config_yml         = filesha256("${path.module}/../../config/forgejo-runner/config.yml")
    cleanup_script     = filesha256("${path.module}/../../scripts/forgejo-runner-cleanup.sh")
    cleanup_service    = filesha256("${path.module}/../../config/forgejo-runner/cleanup.service")
    cleanup_timer      = filesha256("${path.module}/../../config/forgejo-runner/cleanup.timer")
  }
  lifecycle {
    replace_triggered_by = [proxmox_virtual_environment_vm.runner]
  }
  connection {
    type        = "ssh"
    host        = self.triggers.host
    user        = var.vm_username
    private_key = file(pathexpand("~/.ssh/id_ed25519"))
    timeout     = "10m"
  }
  provisioner "remote-exec" {
    inline = ["sudo -n install -d -o $(id -u) -g $(id -g) -m 0750 /opt/forgejo-runner"]
  }
  provisioner "file" {
    source      = "${path.module}/../../scripts/docker.sh"
    destination = "/opt/forgejo-runner/docker.sh"
  }
  provisioner "file" {
    source      = "${path.module}/../../docker/forgejo-runner/docker-compose.yml"
    destination = "/opt/forgejo-runner/docker-compose.yml"
  }
  provisioner "file" {
    source      = "${path.module}/../../config/forgejo-runner/config.yml"
    destination = "/opt/forgejo-runner/config.template.yml"
  }
  provisioner "file" {
    source      = "${path.module}/../../scripts/forgejo-runner-config.py"
    destination = "/opt/forgejo-runner/merge-config.py"
  }
  provisioner "file" {
    source      = "${path.module}/../../scripts/forgejo-runner-drain.py"
    destination = "/opt/forgejo-runner/drain.py"
  }
  provisioner "file" {
    source      = "${path.module}/../../scripts/forgejo-runner-cleanup.sh"
    destination = "/opt/forgejo-runner/cleanup.sh"
  }
  provisioner "file" {
    source      = "${path.module}/../../config/forgejo-runner/cleanup.service"
    destination = "/opt/forgejo-runner/cleanup.service"
  }
  provisioner "file" {
    source      = "${path.module}/../../config/forgejo-runner/cleanup.timer"
    destination = "/opt/forgejo-runner/cleanup.timer"
  }
  provisioner "remote-exec" {
    inline = [
      "set -eu",
      "sudo -n cloud-init status --wait --format json > /tmp/chillilime-cloud-init-status.json || test $? -eq 2",
      "python3 -c 'import json; s=json.load(open(\"/tmp/chillilime-cloud-init-status.json\")); assert s[\"status\"] == \"done\" and not s[\"errors\"] and set(s.get(\"recoverable_errors\", {})) <= {\"DEPRECATED\"}, s'",
      "sudo -n bash -e /opt/forgejo-runner/docker.sh",
      "sudo -n install -o root -g root -m 0755 /opt/forgejo-runner/cleanup.sh /usr/local/sbin/forgejo-runner-cleanup",
      "sudo -n install -o root -g root -m 0644 /opt/forgejo-runner/cleanup.service /etc/systemd/system/forgejo-runner-cleanup.service",
      "sudo -n install -o root -g root -m 0644 /opt/forgejo-runner/cleanup.timer /etc/systemd/system/forgejo-runner-cleanup.timer",
      "sudo -n systemctl daemon-reload",
      "sudo -n systemctl enable --now forgejo-runner-cleanup.timer",
      "sudo -n install -d -m 0700 /var/lib/forgejo-runner",
      "sudo -n apt-get install -y python3-yaml",
      "sudo -n python3 /opt/forgejo-runner/merge-config.py /opt/forgejo-runner/config.template.yml /opt/forgejo-runner/config.yml",
      "sudo -n apt-get install -y prometheus-node-exporter",
      "sudo -n systemctl enable --now prometheus-node-exporter",
      "sudo -n docker compose -f /opt/forgejo-runner/docker-compose.yml config --quiet",
      "sudo -n docker compose -f /opt/forgejo-runner/docker-compose.yml pull",
      "if sudo -n grep -q \"server\" /opt/forgejo-runner/config.yml || sudo -n test -s /var/lib/forgejo-runner/.runner; then sudo -n docker compose -f /opt/forgejo-runner/docker-compose.yml up -d --force-recreate; else echo 'Runner prepared; register it as described in README before starting.'; fi"
    ]
  }
}
