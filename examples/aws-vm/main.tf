/**
 * Single-VM Lighthouse on AWS. The user_data module bootstraps the
 * agent via install.sh on first boot.
 */

terraform {
  required_providers {
    statusharbor = { source = "statusharbor/statusharbor" }
    aws          = { source = "hashicorp/aws" }
  }
}

provider "statusharbor" {
  api_token = var.statusharbor_api_token
}

provider "aws" {
  region = "us-east-1"
}

resource "statusharbor_lighthouse" "homelab" {
  name = "aws-vpc"
}

module "lighthouse_init" {
  source = "../../modules/cloud-init"
  token  = statusharbor_lighthouse.homelab.token
}

resource "aws_instance" "agent" {
  ami                         = "ami-0c7217cdde317cfec" # Ubuntu 22.04 LTS in us-east-1
  instance_type               = "t4g.nano"
  user_data                   = module.lighthouse_init.user_data
  user_data_replace_on_change = true

  tags = {
    Name = "statusharbor-lighthouse"
  }
}

variable "statusharbor_api_token" {
  type      = string
  sensitive = true
}
