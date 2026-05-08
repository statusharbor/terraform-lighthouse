# `modules/cloud-init`

Emits a `user_data` / startup-script string that bootstraps the
Lighthouse agent on first boot of a Linux VM. Wire it into your
cloud-provider VM resource.

## Usage

### AWS

```hcl
resource "statusharbor_lighthouse" "vpc" {
  name = "prod-vpc"
}

module "lighthouse_init" {
  source = "github.com/statusharbor/terraform-lighthouse//modules/cloud-init?ref=v0.1.0"
  token  = statusharbor_lighthouse.vpc.token
}

resource "aws_instance" "agent" {
  ami           = "ami-..."
  instance_type = "t4g.nano"

  user_data                   = module.lighthouse_init.user_data
  user_data_replace_on_change = true
}
```

### GCP

```hcl
resource "google_compute_instance" "agent" {
  name         = "lighthouse"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  metadata = {
    startup-script = module.lighthouse_init.user_data
  }
}
```

### Azure

```hcl
resource "azurerm_linux_virtual_machine" "agent" {
  name                = "lighthouse"
  # ...
  custom_data = module.lighthouse_init.user_data_base64
}
```

## Inputs

| Name    | Type   | Default               |
| ------- | ------ | --------------------- |
| `token` | string | (required, sensitive) |

## Outputs

| Name               | Description                                                     |
| ------------------ | --------------------------------------------------------------- |
| `user_data`        | Bootstrap shell script. Sensitive — contains the bearer token.  |
| `user_data_base64` | Base64-encoded form for Azure `custom_data`.                    |

## Security note

The token is baked into the user_data string as plaintext. AWS
encrypts user_data at rest for EBS-backed AMIs; check your provider's
guarantees. For higher security, use a secret manager (AWS SSM,
GCP Secret Manager, Azure Key Vault) and have the VM pull at boot —
but that's heavier than what this module ships.
