variable "token" {
  description = "Lighthouse bearer token. Mint via the statusharbor_lighthouse resource and pipe in. Sensitive — persists in Helm release state."
  type        = string
  sensitive   = true
}

variable "release_name" {
  description = "Helm release name."
  type        = string
  default     = "lighthouse"
}

variable "namespace" {
  description = "Kubernetes namespace to install into."
  type        = string
  default     = "status-harbor"
}

variable "create_namespace" {
  description = "Create the namespace if it doesn't exist."
  type        = bool
  default     = true
}

variable "chart_version" {
  description = "Helm chart version (defaults to the chart's latest)."
  type        = string
  default     = null
}

variable "image_tag" {
  description = "Override the agent image tag. null = use the chart's appVersion."
  type        = string
  default     = null
}

variable "discovery_enabled" {
  description = "Enable Kubernetes Ingress + Service auto-discovery. Default in the chart is also true."
  type        = bool
  default     = true
}

variable "discovery_namespaces" {
  description = "Namespaces to watch for discovery. Empty list or [\"*\"] means all-namespaces (cluster-scoped RBAC). A named list installs per-namespace Roles instead."
  type        = list(string)
  default     = ["*"]
}

variable "extra_values" {
  description = "Extra Helm values as a flat map of dotted-path keys. Use for tuning resources, persistence, securityContext, etc."
  type        = map(string)
  default     = {}
}

variable "atomic" {
  description = "Helm atomic — roll back on failed install."
  type        = bool
  default     = true
}

variable "wait" {
  description = "Helm wait — block until resources are ready."
  type        = bool
  default     = true
}

variable "timeout_seconds" {
  description = "Helm timeout for install/upgrade."
  type        = number
  default     = 300
}
