/**
 * End-to-end example: provision a Lighthouse on the Console + deploy
 * the agent to an EKS cluster. Assumes you've configured the kubernetes
 * + helm + statusharbor providers elsewhere.
 */

terraform {
  required_providers {
    statusharbor = { source = "statusharbor/statusharbor" }
    helm         = { source = "hashicorp/helm" }
  }
}

provider "statusharbor" {
  api_token = var.statusharbor_api_token
}

resource "statusharbor_lighthouse" "prod" {
  name                      = "prod-eks"
  notify_on_lifecycle       = true
  flap_protection_threshold = 1
}

module "lighthouse" {
  source = "../../modules/helm"

  release_name         = "lighthouse"
  namespace            = "status-harbor"
  token                = statusharbor_lighthouse.prod.token
  discovery_namespaces = ["*"]
}

variable "statusharbor_api_token" {
  type      = string
  sensitive = true
}
