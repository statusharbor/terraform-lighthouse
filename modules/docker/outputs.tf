output "container_id" {
  description = "Docker container ID."
  value       = docker_container.lighthouse.id
}

output "container_name" {
  description = "Container name (echoed back)."
  value       = docker_container.lighthouse.name
}

output "image" {
  description = "Image reference actually running."
  value       = docker_container.lighthouse.image
}
