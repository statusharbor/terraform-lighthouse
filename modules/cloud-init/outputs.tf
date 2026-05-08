output "user_data" {
  description = "Bootstrap shell script. Wire into aws_instance.user_data, google_compute_instance.metadata.startup-script, or azurerm_linux_virtual_machine.custom_data (base64-encoded for Azure)."
  value       = local.user_data
  sensitive   = true
}

output "user_data_base64" {
  description = "Base64-encoded form of the bootstrap script — needed for azurerm_linux_virtual_machine.custom_data."
  value       = base64encode(local.user_data)
  sensitive   = true
}
