output "release_name" {
  description = "Name of the Helm release."
  value       = helm_release.lighthouse.name
}

output "namespace" {
  description = "Kubernetes namespace the agent is installed into."
  value       = helm_release.lighthouse.namespace
}

output "chart_version" {
  description = "Resolved chart version that was installed."
  value       = helm_release.lighthouse.version
}
