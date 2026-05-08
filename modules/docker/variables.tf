variable "token" {
  description = "Lighthouse bearer token. Mint via the statusharbor_lighthouse resource and pipe in. Sensitive."
  type        = string
  sensitive   = true
}

variable "container_name" {
  description = "Name of the Docker container."
  type        = string
  default     = "lighthouse"
}

variable "image_repository" {
  description = "OCI image repository."
  type        = string
  default     = "ghcr.io/statusharbor/lighthouse"
}

variable "image_tag" {
  description = "Image tag to run. Pin a specific version for deterministic deploys; 'latest' auto-upgrades on every recreate."
  type        = string
  default     = "latest"
}

variable "keep_image_locally" {
  description = "Keep the Docker image on the host after `terraform destroy` (faster re-apply at the cost of disk)."
  type        = bool
  default     = true
}

variable "data_dir" {
  description = "Host path mounted at /var/lib/lighthouse. null = ephemeral (offline events lost on restart)."
  type        = string
  default     = null
}

variable "healthcheck_port" {
  description = "If the agent exposes /healthz on this port, run a Docker HEALTHCHECK against it. null disables."
  type        = number
  default     = null
}

variable "extra_env" {
  description = "Extra environment variables in 'KEY=value' form. Useful for LIGHTHOUSE_LOG_LEVEL=debug, etc."
  type        = list(string)
  default     = []
}
