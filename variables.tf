resource "random_string" "unique_id" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
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

variable "retries_count" {
  description = "Maximum number of retries for async invocation."
  type        = number
  default     = 3
}


# Existing service accounts
variable "default_function_service_account_id" {
  description = "Service account ID for Yandex Cloud Function."
  type        = string
  default     = "aje6qgf4roucb39k4e4l"
}
variable "default_invoker_service_account_id" {
  description = "Service account ID for asynchronous invocation."
  type        = string
  default     = "aje91ie59fr034m9v2hi"
}

variable "default_ymq_writer_service_account_id" {
  description = "Service account ID for writing to ymq."
  type        = string
  default     = "ajespehssegbd1ctb5uv"
}

variable "cron_expression" {
  description = "Cron expression for timer for Yandex Cloud Functions Trigger."
  type        = string
  default     = "*/10 * ? * * *"
}

variable "func_iam_binding" {
  description = "The binding for Yandex Cloud Function."
  type        = string
  default     = "admin"
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for messages in a queue, specified in seconds."
  type        = number
  default     = 600
}

variable "receive_wait_time_seconds" {
  description = "Wait time for the ReceiveMessage method (for long polling), in seconds."
  type        = number
  default     = 20
}

variable "message_retention_seconds" {
  description = "The length of time in seconds to retain a message."
  type        = number
  default     = 1209600
}

variable "maxReceiveCount" {
  description = "Maximum number attempts of getting the message before sending it to DLQ"
  type        = number
  default = 3
}

variable "zip_filename" {
  description = "Filename to zip archive for the version."
  type        = string
}

variable "YC_ACCESS_KEY" {
  type        = string
  description = "static access key"
}

variable "YC_SECRET_KEY" {
  type        = string
  description = "secret key"
}

variable "YC_VALUE" {
  type        = string
  description = "value for lockbox secret"
}

variable "lockbox_secret_key" {
  type        = string
  description = "lockbox secret key"
}