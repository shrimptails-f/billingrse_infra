variable "env_subdomain" {
  type        = string
  default     = "dev"
  description = "Environment prefix (e.g., dev -> dev.example.com / api.dev.example.com)."
}
