# Mimics https://github.com/rancher/k3s/blob/master/docker-compose.yml
resource "docker_volume" "k3s_server" {
  name = "k3s-server-${terraform.workspace}"
}

resource "docker_network" "k3s" {
  name = "k3s-${terraform.workspace}"
}

resource "docker_image" "k3s" {
  name = "rancher/k3s:${var.k3s_version}"
}

resource "docker_container" "k3s_server" {
  image = docker_image.k3s.latest
  name  = "k3s-server-${terraform.workspace}"

  command = [
    "server",
    "--disable", "traefik",
    "--disable", "local-storage",
  ]

  tmpfs = {
    "/run"     = "rw",
    "/var/run" = "rw",
  }

  privileged = true

  networks_advanced {
    name    = docker_network.k3s.name
    aliases = ["server"]
  }

  env = [
    "K3S_TOKEN=${random_password.k3s_token.result}",
    "K3S_KUBECONFIG_OUTPUT=/output/kubeconfig.yaml",
    "K3S_KUBECONFIG_MODE=666",
  ]

  volumes {
    volume_name    = docker_volume.k3s_server.name
    container_path = "/var/lib/rancher/k3s"
  }

  volumes {
    host_path      = var.k3s_kubeconfig_dir
    container_path = "/output"
  }

  ports {
    internal = 80
    external = 80
  }

  ports {
    internal = 443
    external = 443
  }

  ports {
    internal = 6443
    external = 6443
  }
}

resource "docker_container" "k3s_agent" {
  image = docker_image.k3s.latest
  name  = "k3s-agent-${terraform.workspace}"

  tmpfs = {
    "/run"     = "rw",
    "/var/run" = "rw",
  }

  privileged = true

  networks_advanced {
    name    = docker_network.k3s.name
    aliases = ["agent"]
  }

  env = [
    "K3S_TOKEN=${random_password.k3s_token.result}",
    "K3S_URL=https://server:6443"
  ]
}

resource "random_password" "k3s_token" {
  length = 16
}
