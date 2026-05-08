/**
 * Status Harbor Lighthouse — Docker install module.
 *
 * Wraps `docker_container` for single-host installs. Pulls the
 * official agent image from GHCR and runs it with --restart=on-failure
 * so a failed start (revoked token, bad config) doesn't loop forever
 * but a transient crash recovers.
 *
 * For Kubernetes installs use `modules/helm` instead. For an
 * AWS/GCP/Azure VM install, see `modules/cloud-init`.
 */

terraform {
  required_version = ">= 1.6"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.0"
    }
  }
}

resource "docker_image" "lighthouse" {
  name         = "${var.image_repository}:${var.image_tag}"
  keep_locally = var.keep_image_locally
}

resource "docker_container" "lighthouse" {
  name  = var.container_name
  image = docker_image.lighthouse.image_id

  restart = "on-failure"

  env = concat(
    [
      "LIGHTHOUSE_TOKEN=${var.token}",
    ],
    var.extra_env,
  )

  # Optional: persist the offline buffer across container restarts.
  dynamic "volumes" {
    for_each = var.data_dir == null ? [] : [1]
    content {
      host_path      = var.data_dir
      container_path = "/var/lib/lighthouse"
    }
  }

  # Health probe via HTTP if exposed.
  dynamic "healthcheck" {
    for_each = var.healthcheck_port == null ? [] : [1]
    content {
      test         = ["CMD", "wget", "-q", "--spider", "http://localhost:${var.healthcheck_port}/healthz/live"]
      interval     = "30s"
      timeout      = "3s"
      retries      = 3
      start_period = "30s"
    }
  }
}
