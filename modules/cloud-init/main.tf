/**
 * Status Harbor Lighthouse — cloud-init / user_data module.
 *
 * Emits a shell script suitable for AWS user_data, GCP startup_script
 * or Azure custom_data. The script downloads + runs the official
 * install.sh on first boot, with the bearer token piped via env so
 * it never lands on disk in plaintext.
 *
 * This module produces no resources — just a string output. Wire
 * the output into your VM resource:
 *
 *     module "lighthouse_init" {
 *       source = "github.com/statusharbor/terraform-lighthouse//modules/cloud-init"
 *       token  = statusharbor_lighthouse.prod.token
 *     }
 *
 *     resource "aws_instance" "agent" {
 *       # ...
 *       user_data = module.lighthouse_init.user_data
 *     }
 */

terraform {
  required_version = ">= 1.6"
}

locals {
  # Single source of truth for the bootstrap script. The token is
  # exported into the install.sh process via env (LIGHTHOUSE_TOKEN)
  # rather than written to a config file on disk first.
  user_data = <<-EOT
    #!/usr/bin/env bash
    set -euo pipefail

    export LIGHTHOUSE_TOKEN=${var.token}

    # Run install.sh non-interactively. The script handles the
    # systemd unit + binary placement.
    curl -fsSL https://lighthouse.statusharbor.io/install.sh | bash

    # Optional: forward the agent's stdout into journald via the
    # systemd unit defaults. Already the default in install.sh.
  EOT
}
