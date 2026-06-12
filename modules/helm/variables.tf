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

variable "k8sstats_enabled" {
  description = "Install the ClusterRole + ClusterRoleBinding the agent's cluster-shape collector needs (nodes / pods / pvc list + nodes/proxy for kubelet /stats/summary). The k8sstats collector starts unconditionally inside the agent when running in Kubernetes; without this RBAC it just logs 403 every tick and the console's `/metrics → Cluster` tab stays empty. On by default because the whole point of running Lighthouse on Kubernetes is to see what the cluster does — flip to false only when the cluster operator deliberately wants to opt out of cluster-scoped RBAC."
  type        = bool
  default     = true
}

variable "daemonset_enabled" {
  description = "Enable the per-node DaemonSet workload (LIGHTHOUSE_ROLE=host_metrics, /host/proc hostPath mount). On by default for the same reason as k8sstats — without the DaemonSet the central pod reads host metrics through its containerised /proc, so CPU / memory get cgroup-skewed and the disk panel shows the pod's pseudo-mounts (/etc/hosts, emptyDirs) instead of node filesystems. Flip to false on clusters where the DaemonSet's hostPath /proc mount is forbidden by Pod Security Admission `restricted` (label the namespace `baseline` or `privileged`, or pass a custom `daemonset.containerSecurityContext` via `extra_values` instead)."
  type        = bool
  default     = true
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
