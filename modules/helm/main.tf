/**
 * Status Harbor Lighthouse — Helm install module.
 *
 * Wraps `helm_release` against the official chart at
 * oci://ghcr.io/statusharbor/charts/lighthouse. Defaults match what
 * a vanilla `helm install` does; override the variables below to
 * tighten RBAC scope, disable discovery, change the image tag, etc.
 *
 * The token is required and sensitive — typically piped from a
 * `statusharbor_lighthouse` resource managed by the
 * `statusharbor/statusharbor` provider:
 *
 *     resource "statusharbor_lighthouse" "prod" {
 *       name = "prod-vpc"
 *     }
 *     module "lighthouse_helm" {
 *       source = "github.com/statusharbor/terraform-lighthouse//modules/helm"
 *       token  = statusharbor_lighthouse.prod.token
 *     }
 */

terraform {
  required_version = ">= 1.6"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13"
    }
  }
}

resource "helm_release" "lighthouse" {
  name       = var.release_name
  namespace  = var.namespace
  repository = "oci://ghcr.io/statusharbor/charts"
  chart      = "lighthouse"
  version    = var.chart_version

  create_namespace = var.create_namespace
  atomic           = var.atomic
  wait             = var.wait
  timeout          = var.timeout_seconds

  set_sensitive {
    name  = "token"
    value = var.token
  }

  dynamic "set" {
    for_each = var.discovery_enabled ? [1] : []
    content {
      name  = "discovery.enabled"
      value = "true"
    }
  }

  # Helm's slice setter form — produces discovery.namespaces[0],
  # discovery.namespaces[1], …
  dynamic "set" {
    for_each = var.discovery_namespaces
    content {
      name  = "discovery.namespaces[${set.key}]"
      value = set.value
    }
  }

  dynamic "set" {
    for_each = var.image_tag == null ? [] : [1]
    content {
      name  = "image.tag"
      value = var.image_tag
    }
  }

  dynamic "set" {
    for_each = var.daemonset_enabled ? [1] : []
    content {
      name  = "daemonset.enabled"
      value = "true"
    }
  }

  # Bind-mount host's / read-only into the DaemonSet so the disk
  # collector statfs()es real host filesystems. Gated on daemonset_enabled
  # because mountHostRoot is meaningless without the DaemonSet — but
  # always sent (both true AND false) when the DaemonSet is on, so the
  # operator's explicit choice in this module overrides any future drift
  # in the chart's default. Without that, a chart upgrade that flipped
  # the default would silently change this module's behaviour.
  dynamic "set" {
    for_each = var.daemonset_enabled ? [1] : []
    content {
      name  = "daemonset.mountHostRoot"
      value = var.daemonset_mount_host_root ? "true" : "false"
    }
  }

  # Helm's slice setter form for the DaemonSet extraEnv list — each
  # entry becomes two `--set` flags (name + value) addressed via the
  # array-index path. The chart's daemonset.yaml template walks
  # .Values.daemonset.extraEnv with `toYaml` so the final container
  # spec receives one env entry per object.
  dynamic "set" {
    for_each = var.daemonset_extra_env
    content {
      name  = "daemonset.extraEnv[${set.key}].name"
      value = set.value.name
    }
  }
  dynamic "set" {
    for_each = var.daemonset_extra_env
    content {
      name  = "daemonset.extraEnv[${set.key}].value"
      value = set.value.value
    }
  }

  dynamic "set" {
    for_each = var.extra_values
    content {
      name  = set.key
      value = set.value
    }
  }
}
