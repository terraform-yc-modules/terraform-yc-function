resource "random_string" "unique_id" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

variable "lockbox_secret_key" {
  description = "Lockbox secret key."
  type        = string
  default     = null
}

variable "lockbox_secret_value" {
  description = "Lockbox secret value."
  type        = string
  default     = null
}
