# `modules/docker`

Runs the Lighthouse agent as a Docker container on a host you've
already wired the [`kreuzwerker/docker`](https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs)
provider against.

## Usage

```hcl
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

resource "statusharbor_lighthouse" "homelab" {
  name = "homelab"
}

module "lighthouse" {
  source = "github.com/statusharbor/terraform-lighthouse//modules/docker?ref=v0.1.0"

  token     = statusharbor_lighthouse.homelab.token
  image_tag = "1.10.2"           # pin for deterministic re-applies
  data_dir  = "/var/lib/lighthouse"
}
```

## Inputs

| Name                 | Type           | Default                              | Notes                                              |
| -------------------- | -------------- | ------------------------------------ | -------------------------------------------------- |
| `token`              | string         | (required, sensitive)                | Lighthouse bearer token.                           |
| `container_name`     | string         | `lighthouse`                         | Container name on the host.                        |
| `image_repository`   | string         | `ghcr.io/statusharbor/lighthouse`    |                                                    |
| `image_tag`          | string         | `latest`                             | Pin to a specific version for deterministic re-applies. |
| `keep_image_locally` | bool           | `true`                               | Keep the image after `terraform destroy`.          |
| `data_dir`           | string         | `null` (ephemeral)                   | Host path mounted at `/var/lib/lighthouse` for offline buffer. |
| `healthcheck_port`   | number         | `null`                               | If the agent exposes `/healthz` on this port, run Docker `HEALTHCHECK`. |
| `extra_env`          | list(string)   | `[]`                                 | Additional `KEY=value` env vars.                   |

## Outputs

| Name             | Description                       |
| ---------------- | --------------------------------- |
| `container_id`   | Docker container ID.              |
| `container_name` | Container name (echoed back).     |
| `image`          | Image reference actually running. |
