variable "env_subdomain" {
  type        = string
  default     = "dev"
  description = "Environment prefix (e.g. dev -> dev.example.com)."
}

variable "from_local_part" {
  type        = string
  default     = "no-reply"
  description = "Local part used for the default sender address."
}

variable "dmarc_policy" {
  type        = string
  default     = "none"
  description = "DMARC policy. Start with none and raise to quarantine/reject after validation."

  validation {
    condition     = contains(["none", "quarantine", "reject"], var.dmarc_policy)
    error_message = "dmarc_policy must be one of: none, quarantine, reject."
  }
}

variable "dmarc_adkim" {
  type        = string
  default     = "r"
  description = "DKIM alignment mode for DMARC. Use r (relaxed) or s (strict)."

  validation {
    condition     = contains(["r", "s"], var.dmarc_adkim)
    error_message = "dmarc_adkim must be either r or s."
  }
}

variable "dmarc_aspf" {
  type        = string
  default     = "r"
  description = "SPF alignment mode for DMARC. Use r (relaxed) or s (strict)."

  validation {
    condition     = contains(["r", "s"], var.dmarc_aspf)
    error_message = "dmarc_aspf must be either r or s."
  }
}
