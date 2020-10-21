# Mimics https://github.com/rancher/k3s/blob/master/docker-compose.yml
resource "docker_volume" "k3s_server" {
  name = "k3s-server-${var.cluster_name}"
}

resource "docker_network" "k3s" {
  name = "k3s-${var.cluster_name}"
}

resource "docker_image" "registry" {
  name         = "registry:2"
  keep_locally = true
}

resource "docker_container" "registry_dockerio" {
  image = docker_image.registry.latest
  name  = "registry-dockerio-${var.cluster_name}"

  networks_advanced {
    name    = docker_network.k3s.name
    aliases = ["registry-dockerio"]
  }

  env = [
    "REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io",
  ]

  mounts {
    target = "/var/lib/registry"
    source = "registry"
    type   = "volume"
  }
}

resource "docker_container" "registry_quayio" {
  image = docker_image.registry.latest
  name  = "registry-quayio-${var.cluster_name}"

  networks_advanced {
    name    = docker_network.k3s.name
    aliases = ["registry-quayio"]
  }

  env = [
    "REGISTRY_PROXY_REMOTEURL=https://quay.io/repository",
    "REGISTRY_COMPATIBILITY_SCHEMA1_ENABLED=true"
  ]

  mounts {
    target = "/var/lib/registry"
    source = "registry"
    type   = "volume"
  }
}

resource "docker_container" "registry_gcrio" {
  image = docker_image.registry.latest
  name  = "registry-gcrio-${var.cluster_name}"

  networks_advanced {
    name    = docker_network.k3s.name
    aliases = ["registry-gcrio"]
  }

  env = [
    "REGISTRY_PROXY_REMOTEURL=https://gcr.io",
  ]

  mounts {
    target = "/var/lib/registry"
    source = "registry"
    type   = "volume"
  }
}

resource "docker_container" "registry_usgcrio" {
  image = docker_image.registry.latest
  name  = "registry-usgcrio-${var.cluster_name}"

  networks_advanced {
    name    = docker_network.k3s.name
    aliases = ["registry-usgcrio"]
  }

  env = [
    "REGISTRY_PROXY_REMOTEURL=https://us.gcr.io",
  ]

  mounts {
    target = "/var/lib/registry"
    source = "registry"
    type   = "volume"
  }
}

resource "docker_image" "k3s" {
  name         = "rancher/k3s:${var.k3s_version}"
  keep_locally = true
}

resource "docker_volume" "k3s_server_kubelet" {
  name = "k3s-server-kubelet-${var.cluster_name}"
}

resource "docker_container" "k3s_server" {
  image = docker_image.k3s.latest
  name  = "k3s-server-${var.cluster_name}"

  command = [
    "server",
    "--disable", "traefik",
    "--disable", "local-storage",
  ]

  privileged = true

  networks_advanced {
    name    = docker_network.k3s.name
    aliases = ["server"]
  }

  env = [
    "K3S_TOKEN=${random_password.k3s_token.result}",
  ]

  mounts {
    target = "/run"
    type   = "tmpfs"
  }

  mounts {
    target = "/var/run"
    type   = "tmpfs"
  }

  mounts {
    target = "/etc/rancher/k3s/registries.yaml"
    source = "${abspath(path.module)}/registries.yaml"
    type   = "bind"
  }

  mounts {
    target = "/var/lib/rancher/k3s"
    source = docker_volume.k3s_server.name
    type   = "volume"
  }

  mounts {
    target = "/var/lib/kubelet"
    source = docker_volume.k3s_server_kubelet.mountpoint
    type   = "bind"

    bind_options {
      propagation = "rshared"
    }
  }
}

resource "docker_volume" "k3s_agent_kubelet" {
  count = var.node_count

  name = "k3s-agent-kubelet-${var.cluster_name}-${count.index}"
}

resource "docker_container" "k3s_agent" {
  count = var.node_count

  image = docker_image.k3s.latest
  name  = "k3s-agent-${var.cluster_name}-${count.index}"

  privileged = true

  networks_advanced {
    name = docker_network.k3s.name
  }

  env = [
    "K3S_TOKEN=${random_password.k3s_token.result}",
    "K3S_URL=https://server:6443",
  ]

  mounts {
    target = "/run"
    type   = "tmpfs"
  }

  mounts {
    target = "/var/run"
    type   = "tmpfs"
  }

  mounts {
    target = "/etc/rancher/k3s/registries.yaml"
    source = "${abspath(path.module)}/registries.yaml"
    type   = "bind"
  }

  mounts {
    target = "/var/lib/kubelet"
    source = docker_volume.k3s_agent_kubelet[0].mountpoint
    type   = "bind"

    bind_options {
      propagation = "rshared"
    }
  }
}

resource "random_password" "k3s_token" {
  length = 16
}
