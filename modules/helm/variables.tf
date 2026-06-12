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

variable "daemonset_enabled" {
  description = "Enable the per-node DaemonSet workload (LIGHTHOUSE_ROLE=host_metrics, /host/proc hostPath mount). Off by default to match the chart so `terraform apply` is a no-op for installs that don't want per-node metrics. Note: the DaemonSet's hostPath /proc mount is forbidden under the `restricted` Pod Security Admission profile — label the namespace `baseline` or `privileged`, or pass a custom `daemonset.containerSecurityContext` via `extra_values`."
  type        = bool
  default     = false
}

variable "daemonset_mount_host_root" {
  description = "Bind-mount the node's / read-only at /host/root in the DaemonSet pods and point the disk collector at it via LIGHTHOUSE_HOST_ROOT. Without this, /proc/mounts (read via the /host/proc bind-mount) lists the node's mountpoints correctly but syscall.Statfs resolves each path through the pod's own mount namespace — so disk_used_bytes / disk_used_percent reflect the container's view (emptyDirs, /etc/hosts) instead of the node. On by default once the DaemonSet itself is enabled: turning on per-node metrics implies you want them correct, and silently wrong disk numbers are a worse failure mode than the (read-only, opt-in) privilege surface. Set to false on clusters where PSA `restricted` or OPA/Gatekeeper/Kyverno policies forbid hostPath: / even read-only. Linux nodes only — the env var is read by the Linux host-metrics collector; darwin / windows use platform APIs and ignore it. Only meaningful when daemonset_enabled = true."
  type        = bool
  default     = true
}

variable "daemonset_extra_env" {
  description = "Extra environment variables for the per-node DaemonSet pods. Each entry maps to one container env entry. Useful for HTTP(S)_PROXY, custom NODE_NAME overrides, etc. Empty list = nothing added. Only meaningful when daemonset_enabled = true."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
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
