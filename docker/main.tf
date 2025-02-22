terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "docker_container" "nginx" {
  name  = "mynginx"
  image = docker_image.nginx.image_id

  ports {
    internal = "80"
    external = "8080"
  }
}

resource "docker_image" "nginx" {
  name = "nginx:latest"
}

resource "docker_volume" "shared_volume" {
  name = "shared_volume"

  driver_opts = {
    type   = "none"
    device = "/tmp/shared_volume"
    o      = "bind"
  }
}
