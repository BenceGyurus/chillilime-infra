output "forgejo_url" {
  value = var.forgejo_root_url
}
output "runner_ip" {
  value = split("/", var.runner_address)[0]
}
