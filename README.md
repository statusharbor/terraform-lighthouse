# terraform-lighthouse

Terraform modules that deploy the [Status Harbor Lighthouse agent](https://www.statusharbor.io/private-network-monitoring)
to the place it actually runs — Kubernetes (Helm), Docker, or a Linux
VM via cloud-init.

These modules are **infrastructure deployment**. The Lighthouse
*resource* itself (its registration with the Console + bearer token)
is managed by the [`statusharbor`](https://github.com/statusharbor/terraform-provider-statusharbor)
provider. Typical wiring:

```hcl
resource "statusharbor_lighthouse" "prod_vpc" {
  name = "prod-vpc"
}

module "lighthouse_helm" {
  source = "github.com/statusharbor/terraform-lighthouse//modules/helm"

  release_name = "lighthouse"
  namespace    = "status-harbor"
  token        = statusharbor_lighthouse.prod_vpc.token
}
```

## Modules

| Path                     | What it does                                      |
| ------------------------ | ------------------------------------------------- |
| `modules/helm/`          | Wraps `helm_release` against the official chart   |
| `modules/docker/`        | Wraps `docker_container` for single-host installs |
| `modules/cloud-init/`    | Emits a `user_data` script for AWS/GCP/Azure VMs  |

Each module's README lists the inputs and outputs.

## Versioning

Tagged releases (`vX.Y.Z`) — pin in the `source` URL with `?ref=`:

```hcl
source = "github.com/statusharbor/terraform-lighthouse//modules/helm?ref=v0.1.0"
```

Module API stability follows the convention: minor bumps for new
inputs (with sensible defaults), major bumps for renames or removals.

## License

Apache 2.0 — see [`LICENSE`](LICENSE).
