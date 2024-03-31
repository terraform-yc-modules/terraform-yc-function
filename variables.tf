resource "random_string" "unique_id" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

variable "tags" {
  description = "Tags for Cloud Function."
  type        = list(string)
  default     = ["yc_tag"]
}

variable "user_hash" {
  description = <<EOF
    User-defined string for current function version.
    User must change this string any times when function changed. 
    Function will be updated when hash is changed."
  EOF
  default     = "yc-defined-string-for-tf-module"
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

variable "existing_service_account_name" {
  description = "Existing IAM service account name."
  type        = string
  default     = null
}

variable "existing_service_account_id" {
  description = "Existing IAM service account id."
  type        = string
  default     = null # "ajebc0l7qlklv3em6ln9"
}

variable "use_existing_sa" {
  description = <<EOF
    Use existing service accounts (true) or not (false).
    If `true` parameters `existing_service_account_id` must be set.
  EOF
  type        = bool
  default     = false
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
  default     = "../../handler.zip"
}

variable "choosing_trigger_type" {
  description = "Choosing type for cloud function trigger"
  type        = string
  default     = "logging"
  validation {
    condition     = contains(["logging", "timer", "object_storage", "message_queue"], var.choosing_trigger_type)
    error_message = "Trigger type should be logging, timer, object_storage or message_queue."
  }
}

variable "logging" {
  description = "Trigger type of logging."
  type = object({
    group_id       = string
    resource_types = list(string)
    levels         = list(string)
    batch_cutoff   = number
    batch_size     = number
  })
  default = {
    group_id       = "e23moaejmq8m74tssfu9"
    resource_types = ["serverless.function"]
    levels         = ["INFO"]
    batch_cutoff   = 1
    batch_size     = 1
  }
}

variable "timer" {
  description = "Trigger type of timer."
  type = object({
    cron_expression = string
  })
  default = {
    cron_expression = "*/15 * ? * * *"
  }
}

variable "object_storage" {
  description = "Trigger type of object storage."
  type = object({
    bucket_id    = string
    create       = bool
    update       = bool
    delete       = bool
    batch_cutoff = number
    batch_size   = number
  })
  default = {
    bucket_id    = "yandex-cloud-nnn"
    create       = true
    update       = true
    delete       = true
    batch_cutoff = 1
    batch_size   = 1
  }
}

variable "message_queue" {
  description = "Trigger type of message queue."
  type = object({
    queue_id           = string
    service_account_id = string
    batch_cutoff       = number
    batch_size         = number
    visibility_timeout = number
  })
  default = {
    queue_id           = "yrn:yc:ymq:ru-central1:b1gfl7u3a9ahaamt3ore:anana"
    service_account_id = "ajeaebn6c3kfoekg9h3b"
    batch_cutoff       = 1
    batch_size         = 1
    visibility_timeout = 600
  }
}

variable "use_existing_log_group" {
  description = <<EOF
    Use existing logging group (true) or not (false).
    If `true` parameters `existing_log_group_id` must be set.
  EOF
  type        = bool
  default     = false
}

variable "existing_log_group_id" {
  description = "Existing logging group id."
  type        = string
  default     = null # "e23moaejmq8m74tssfu9"
}

variable "min_level" {
  description = "Minimal level of logging for Cloud Funcion."
  type        = string
  default     = "ERROR"
}

variable "lockbox_secret_key" {
  description = "Lockbox secret key."
  type        = string
  default     = "yc-key" # use .tfvars instead of default key
}

variable "lockbox_secret_value" {
  description = "Lockbox secret value."
  type        = string
  default     = "yc-value" # use .tfvars instead of default value
}

variable "environment_variable" {
  description = "Function's environment variable in which secret's value will be stored."
  type        = string
  default     = "ENV_VARIABLE"
}
