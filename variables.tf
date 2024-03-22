resource "random_string" "unique_id" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

variable "policy" {
  description = "List definition for Yandex Cloud Function scaling policies."
  type = map(any)
  default = {
    tag      = "$latest"
    zone_instances_limit = 3
    zone_requests_limit = 100
  }
}

variable "service_account_name" {
  description = "IAM service account name."
  type        = string
  default     = "function-service-account"
}

variable "use_existing_sa" {
  description = <<EOF
    Use existing service accounts (true) or not (false).
  EOF
  type        = bool
  default     = false
}

variable "create_logging_group" {
  description = "Flag for enabling or disabling logging group creation."
  type        = bool
  default     = true
}

variable "folder_id" {
  description = "The ID of the folder that the Cloud Function belongs to."
  type        = string
  default     = null
}
variable "runtime" {
  description = "Runtime for Yandex Cloud Function."
  type        = string
  default     = "bash-2204"
}

variable "entrypoint" {
  description = "Entrypoint for Yandex Cloud Function."
  type        = string
  default     = "handler.sh"
}

variable "memory" {
  description = "Memory in megabytes for Yandex Cloud Function."
  type        = number
  default     = 128
}

variable "execution_timeout" {
  description = "Execution timeout in seconds for Yandex Cloud Function."
  type        = number
  default     = 10
}

variable "zip_filename" {
  description = "Filename to zip archive for the version."
  type        = string
}