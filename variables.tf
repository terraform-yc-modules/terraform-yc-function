resource "random_string" "unique_id" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

variable "cron_expression" {
  description = "value"
  default     = "*/15 * ? * * *"
  type        = string
}

variable "user_hash" {
  description = <<EOF
    User-defined string for current function version.
    User must change this string any times when function changed. 
    Function will be updated when hash is changed."
  EOF
  default     = "yc-defined-string"
  type        = string
}

variable "policy" {
  description = "List definition for Yandex Cloud Function scaling policies."
  type        = map(any)
  default = {
    tag                  = "$latest"
    zone_instances_limit = 3
    zone_requests_limit  = 100
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

variable "create_logging_group_or_timer" {
  description = "Flag for enabling logging group creation (true) or enabling timer with cron expression (false)."
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
