variable "folder_id" {
  description = "The ID of the folder that the Cloud Function belongs to."
  type        = string
  default     = null
}

resource "random_string" "unique_id" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}