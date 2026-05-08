variable "token" {
  description = "Lighthouse bearer token. Mint via the statusharbor_lighthouse resource and pipe in. Sensitive — gets baked into the user_data script as plaintext, so use with cloud-provider-encrypted user_data fields where available (AWS user_data is encrypted at rest in EBS-backed AMIs)."
  type        = string
  sensitive   = true
}
