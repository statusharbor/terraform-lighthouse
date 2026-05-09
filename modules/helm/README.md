# `modules/helm`

Installs the Status Harbor Lighthouse agent on Kubernetes via the
official Helm chart (`oci://ghcr.io/statusharbor/charts/lighthouse`).

## Usage

```hcl
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "statusharbor_lighthouse" "prod" {
  name = "prod-vpc"
}

module "lighthouse" {
  source = "github.com/statusharbor/terraform-lighthouse//modules/helm?ref=v0.1.0"

  release_name = "lighthouse"
  namespace    = "status-harbor"
  token        = statusharbor_lighthouse.prod.token

  # All-namespaces discovery (default). Pass a named list like
  # ["prod", "staging"] to scope and downgrade RBAC from
  # cluster-scoped to per-namespace Roles.
  discovery_namespaces = ["*"]
}
```

## Inputs

| Name                   | Type           | Default              | Notes                                                |
| ---------------------- | -------------- | -------------------- | ---------------------------------------------------- |
| `token`                | string         | (required, sensitive)| Lighthouse bearer token from `statusharbor_lighthouse.token`. |
| `release_name`         | string         | `lighthouse`         | Helm release name.                                   |
| `namespace`            | string         | `status-harbor`      | Kubernetes namespace.                                |
| `create_namespace`     | bool           | `true`               | Create the namespace if missing.                     |
| `chart_version`        | string         | latest               | Pin a specific chart version.                        |
| `image_tag`            | string         | chart's appVersion   | Override the agent image tag.                        |
| `discovery_enabled`    | bool           | `true`               | Enable Ingress + Service auto-discovery.             |
| `discovery_namespaces` | list(string)   | `["*"]`              | Namespaces to watch (`*` = cluster-scoped RBAC).     |
| `extra_values`         | map(string)    | `{}`                 | Flat dotted-path map for any additional chart values.|
| `atomic`               | bool           | `true`               | Roll back on failed install.                         |
| `wait`                 | bool           | `true`               | Block until pods are ready.                          |
| `timeout_seconds`      | number         | `300`                | Helm timeout for install/upgrade.                    |

## Outputs

| Name             | Description                                  |
| ---------------- | -------------------------------------------- |
| `release_name`   | Helm release name (echoed back).             |
| `namespace`      | Namespace the agent is installed into.       |
| `chart_version`  | Resolved chart version actually installed.   |
