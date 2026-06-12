# `modules/helm`

Installs the Status Harbor Lighthouse agent on Kubernetes via the
official Helm chart (`oci://ghcr.io/statusharbor/charts/lighthouse`).

## Usage

```hcl
provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

resource "statusharbor_lighthouse" "prod" {
  name = "prod-vpc"
}

module "lighthouse" {
  source = "github.com/statusharbor/terraform-lighthouse//modules/helm?ref=v0.1.0"

  release_name = "lighthouse"
  namespace    = "status-harbor"
  token        = statusharbor_lighthouse.prod.token

  # All-namespaces discovery (default). Pass a named list like
  # ["prod", "staging"] to scope and downgrade RBAC from
  # cluster-scoped to per-namespace Roles.
  discovery_namespaces = ["*"]
}
```

## Inputs

| Name                   | Type           | Default              | Notes                                                |
| ---------------------- | -------------- | -------------------- | ---------------------------------------------------- |
| `token`                | string         | (required, sensitive)| Lighthouse bearer token from `statusharbor_lighthouse.token`. |
| `release_name`         | string         | `lighthouse`         | Helm release name.                                   |
| `namespace`            | string         | `status-harbor`      | Kubernetes namespace.                                |
| `create_namespace`     | bool           | `true`               | Create the namespace if missing.                     |
| `chart_version`        | string         | latest               | Pin a specific chart version.                        |
| `image_tag`            | string         | chart's appVersion   | Override the agent image tag.                        |
| `discovery_enabled`    | bool           | `true`               | Enable Ingress + Service auto-discovery.             |
| `discovery_namespaces` | list(string)   | `["*"]`              | Namespaces to watch (`*` = cluster-scoped RBAC).     |
| `daemonset_enabled`    | bool           | `false`              | Install the per-node host-metrics DaemonSet. See PSA caveat below. |
| `daemonset_mount_host_root` | bool      | `true`               | Bind-mount the node's `/` read-only at `/host/root` so disk metrics reflect the node, not the container. Linux nodes only. Set `false` on clusters whose PSA / admission policies forbid `hostPath: /`. Only meaningful when `daemonset_enabled = true`. See host-metrics section below. |
| `daemonset_extra_env`  | list(object{name,value}) | `[]`      | Extra env vars for the DaemonSet pods (proxies, etc.). |
| `extra_values`         | map(string)    | `{}`                 | Flat dotted-path map for any additional chart values.|
| `atomic`               | bool           | `true`               | Roll back on failed install.                         |
| `wait`                 | bool           | `true`               | Block until pods are ready.                          |
| `timeout_seconds`      | number         | `300`                | Helm timeout for install/upgrade.                    |

## Outputs

| Name             | Description                                  |
| ---------------- | -------------------------------------------- |
| `release_name`   | Helm release name (echoed back).             |
| `namespace`      | Namespace the agent is installed into.       |
| `chart_version`  | Resolved chart version actually installed.   |

## Shared-token model (multi-instance Lighthouses)

The Helm flavour intentionally runs the agent as multiple pods sharing
one `lighthouse:write` token — a central Deployment for checks +
discovery, and (when the chart enables it) a DaemonSet for per-node
host metrics. The Console detects this automatically on first
registration: an agent whose `KUBERNETES_SERVICE_HOST` env var is set
sends `runtime: "kubernetes"` and the server flips
`lighthouses.allow_multi_instance = true` (sticky update — never
lowered automatically). After the flip:

- All pods sharing the token are accepted; no `409 Conflict` between
  them. The single-active-instance protection that catches token theft
  on bare-metal installs is bypassed for this Lighthouse.
- The Console maintains a per-node ledger (`lighthouse_active_agents`)
  so per-pod liveness shows up under **Lighthouses → {id} → Active
  agents**. A node that stops heartbeating for 60s triggers a
  per-node offline notification (event `lighthouse.agent_offline`)
  distinct from the whole-Lighthouse one.

Rotating the token continues to work the same way as before — re-mint
via the Console and `helm upgrade` the chart with the new value.
Reusing one token across separate **clusters** is not supported (the
Console expects one cluster = one Lighthouse for node-name
disambiguation).

## Per-node host metrics (DaemonSet flavour)

Enable the chart's DaemonSet workload to ship real per-node CPU /
memory / disk / network metrics. Pass `--set daemonset.enabled=true`
or wire the equivalent into your `extra_values` map.

When enabled, the chart installs a second workload alongside the
central StatefulSet:

- **StatefulSet (central)** — discovery, check scheduling, the
  `k8sstats` cluster-shape collector (`k8s_node_count`,
  `k8s_pods_running`, …), and host metrics scoped to the central
  pod's containerised /proc view.
- **DaemonSet (per-node)** — host metrics only. Reads the **node**'s
  `/proc` through a hostPath mount (`LIGHTHOUSE_PROC_ROOT=/host/proc`)
  and sets `LIGHTHOUSE_ROLE=host_metrics` so it skips the check
  scheduler + discovery watcher.

Both workloads share the same Secret-mounted token and register
against the same Lighthouse. Each DaemonSet pod gets a
`lighthouse_active_agents` row in the Console keyed by
`spec.nodeName` (via the downward API), and the per-node offline
watchdog fires `lighthouse.agent_offline` when a node's heartbeats
stop while the rest of the cluster keeps going.

### Real host disk metrics: `daemonset_mount_host_root`

The DaemonSet pod's host-metrics collector reads the node's
`/proc/mounts` correctly (via the `/host/proc` bind-mount), but
`syscall.Statfs` resolves each mountpoint **through the pod's own
mount namespace**. Mountpoints like `/var/lib/docker` either don't
exist inside the pod (silently skipped) or resolve to a same-named
container path — so without an extra bind-mount, `disk_used_bytes` /
`disk_used_percent` would reflect the container's view (`emptyDir`s,
`/etc/hosts`, `/dev/termination-log`) rather than the node's actual
filesystems.

`daemonset_mount_host_root = true` (the default once
`daemonset_enabled = true`) bind-mounts the node's `/` read-only at
`/host/root` and has the collector statfs the host's real filesystems
via `LIGHTHOUSE_HOST_ROOT=/host/root`. The exposed `mount` label stays
the unprefixed host path so dashboards keep showing `/`,
`/var/lib/docker`, etc. — only the syscall is rerouted. The rationale
for on-by-default: a user who opted into the DaemonSet wants per-node
metrics; silently wrong disk numbers are a worse failure mode than the
read-only hostPath they already implicitly accepted by enabling the
DaemonSet (`/proc` is also a hostPath, just narrower).

When to set `false`:

- The cluster's Pod Security Admission `restricted` profile forbids
  any hostPath, even read-only.
- OPA Gatekeeper / Kyverno / a similar policy engine has a
  `restrict-hostpaths` rule that flags `/`.
- A security review requires explicit justification for every node-fs
  mount and you don't need disk-capacity metrics right now.

Privilege note: `hostPath: /` (read-only) gives the pod the ability
to **read** every file on the node — including kubelet-materialised
Secrets under `/var/lib/kubelet/pods/*/volumes/...`, node-local TLS
keys, and other pods' logs under `/var/log/pods/`. The collector
itself only calls `syscall.Statfs` (capacity metadata, no file
content), but the volume mount can't be narrowed to that one syscall.

Linux nodes only — the env var is read by the Linux host-metrics
collector; darwin / windows collectors use platform APIs and ignore it.

### Pod Security Admission caveat

The DaemonSet pod mounts the node's `/proc` at `/host/proc` (and
optionally `/sys` at `/host/sys` when
`daemonset.mountHostSys=true`). **The `restricted` PSA profile
forbids hostPath volumes outright** — this is a pod-spec
restriction, not a container-security-context one, so adjusting
`runAsNonRoot` / `readOnlyRootFilesystem` / dropping capabilities
does **not** fix the rejection. The install will fail with an
admission-controller error like:

```
hostPath volumes are forbidden (pod or namespace policy: hostPath)
```

The only viable mitigations are namespace-level:

1. **Drop the namespace to `baseline` or `privileged`** (the
   simplest fix on most clusters):
   ```sh
   kubectl label ns status-harbor pod-security.kubernetes.io/enforce=baseline
   ```
   `baseline` is enough — it allows hostPath without granting the
   broader `privileged` capabilities.

2. **Skip the DaemonSet on `restricted` namespaces** by leaving
   `daemonset.enabled=false`. The central StatefulSet still runs
   the k8sstats collector for cluster-shape metrics, just without
   per-node host metrics from each node's /proc. Customers on
   strict-PSA clusters who need per-node metrics typically run the
   DaemonSet in a dedicated namespace labelled `baseline` while
   the rest of their workloads stay on `restricted`.

The container security context (`daemonset.containerSecurityContext`)
is still useful for tuning things the chart's defaults don't cover
(SELinux types, seccomp profiles your cluster mandates) — it just
won't get you past the hostPath rejection.

Control-plane node coverage is on by default — the DaemonSet
tolerates `node-role.kubernetes.io/control-plane:NoSchedule` because
host metrics from control-plane nodes are useful for capacity
planning. Override
`daemonset.tolerations: []` to skip them.

### Terraform example

```hcl
module "lighthouse" {
  source = "github.com/statusharbor/terraform-lighthouse//modules/helm?ref=v0.2.0"

  token              = statusharbor_lighthouse.prod.token
  daemonset_enabled  = true
  daemonset_extra_env = [
    { name = "HTTPS_PROXY", value = "http://proxy.internal:3128" },
    { name = "NO_PROXY",    value = "10.0.0.0/8,.svc.cluster.local" },
  ]
}
```

For knobs the module doesn't expose directly (resource limits,
tolerations beyond the default, custom security contexts), drop into
`extra_values` — every chart value is reachable via its dotted path,
e.g. `daemonset.resources.limits.memory = "128Mi"`.
