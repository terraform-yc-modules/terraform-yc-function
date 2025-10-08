resource "random_string" "unique_id" {
  length  = 8
  upper   = false
  lower   = true
  numeric = true
  special = false
}

variable "tags" {
  description = "List of tags for cloud function yc-function-example."
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

variable "scaling_policy" {
  description = "List of scaling policies for cloud function yc-function-example."
  type = list(object({
    tag                  = string
    zone_instances_limit = number
    zone_requests_limit  = number
  }))
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
  description = "The ID of the folder that the cloud function yc-function-example belongs to."
  type        = string
  default     = null
}
variable "runtime" {
  description = "Runtime for cloud function yc-function-example."
  type        = string
  default     = "bash-2204"
}

variable "entrypoint" {
  description = "Entrypoint for cloud function yc-function-example."
  type        = string
  default     = "handler.sh"
}

variable "memory" {
  description = "Memory in megabytes for cloud function yc-function-example."
  type        = number
  default     = 128

  validation {
    condition = (
      var.memory >= 128 &&
      var.memory <= 4096
    )
    error_message = "Must be between 128 and 4096 seconds, inclusive."
  }
}

variable "execution_timeout" {
  description = "Execution timeout in seconds for cloud function yc-function-example."
  type        = number
  default     = 10
}

variable "zip_filename" {
  description = "Filename to zip archive for the version of cloud function's code."
  type        = string
  default     = "../../handler.zip"
}

variable "choosing_trigger_type" {
  description = "Choosing type for cloud function trigger."
  type        = string
  validation {
    condition     = contains(["logging", "timer", "object_storage", "message_queue", ""], var.choosing_trigger_type)
    error_message = "Trigger type should be logging, timer, object_storage, message_queue or empty string."
  }
}

variable "network_id" {
  description = "Cloud function's network id for VPC integration."
  type        = string
  default     = null # "enp9rm1debn7usfmtlnv"
}

variable "logging" {
  description = "Trigger type of logging."
  type = object({
    group_id       = string
    resource_ids   = optional(list(string))
    resource_types = optional(list(string), ["serverless.function"])
    levels         = optional(list(string), ["INFO"])
    batch_cutoff   = number
    batch_size     = number
    stream_names   = optional(list(string))
  })
  default = {
    group_id     = null
    batch_cutoff = 1
    batch_size   = 1
  }
}

variable "timer" {
  description = "Trigger type of timer."
  type = object({
    cron_expression = optional(string, "*/30 * ? * * *")
    payload         = optional(string)
  })
  default = {
    cron_expression = "*/5 * ? * * *"
    payload         = null
  }
}

variable "object_storage" {
  description = "Trigger type of object storage."
  type = object({
    bucket_id    = string
    prefix       = optional(string)
    suffix       = optional(string)
    create       = optional(bool, true)
    update       = optional(bool, true)
    delete       = optional(bool, true)
    batch_cutoff = number
    batch_size   = number
  })
  default = {
    bucket_id    = null
    batch_cutoff = 1
    batch_size   = 1
  }
}

variable "message_queue" {
  description = "Trigger type of message queue."
  type = object({
    queue_id           = string
    service_account_id = optional(string)
    batch_cutoff       = number
    batch_size         = number
    visibility_timeout = optional(number, 600)
  })
  default = {
    queue_id           = null
    service_account_id = null
    batch_cutoff       = 1
    batch_size         = 1
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
  description = "Minimal level of logging for cloud function yc-function-example."
  type        = string
  default     = "ERROR"
}

variable "lockbox_secret_key" {
  description = "Lockbox secret key for cloud function yc-function-example."
  type        = string
}

variable "lockbox_secret_value" {
  description = "Lockbox secret value for cloud function yc-function-example."
  type        = string
}

variable "existing_secrets" {
  description = "list of existing Lockbox secrets values for cloud function."
  type = list(object({
    id                   = string
    key                  = string
    version_id           = string
    environment_variable = string
  }))
  default = []
}

variable "environment_variable" {
  description = "Function's environment variable in which secret's value will be stored."
  type        = string
  default     = "ENV_VARIABLE"
}

variable "public_access" {
  description = "Making cloud function public (true) or not (false)."
  type        = bool
  default     = false
}

variable "mount_bucket" {
  description = "Mount bucket (true) or not (false). If `true` section `storage_mounts{}` should be defined."
  type        = bool
  default     = false
}

variable "storage_mounts" {
  description = "Mounting s3 bucket."
  type = object({
    mount_point_name = string
    bucket           = string
    prefix           = optional(string)
    read_only        = optional(bool, true)
  })
  default = {
    mount_point_name = "yc-function"
    bucket           = null
  }
}

variable "use_async_invocation" {
  description = "Use asynchronous invocation to message queue (true) or not (false). If `true`, parameters `ymq_success_target` and `ymq_failure_target` must be set."
  type        = bool
  default     = false
}

variable "retries_count" {
  description = "Maximum number of retries for async invocation."
  type        = number
  default     = 3
}

variable "ymq_success_target" {
  description = "Target for successful async invocation."
  type        = string
  default     = null # "yrn:yc:ymq:ru-central1:b1gdddu3a9appamt3aaa:ymq-success"
}

variable "ymq_failure_target" {
  description = "Target for unsuccessful async invocation."
  type        = string
  default     = null # "yrn:yc:ymq:ru-central1:b1gdddu3a9appamt3aaa:ymq-failure"
}

variable "yc_function_name" {
  description = "Custom Cloud Function name from tf-module"
  type        = string
  default     = "yc-custom-function-name"
}

variable "yc_function_description" {
  description = "Custom Cloud Function description from tf-module"
  type        = string
  default     = "yc-custom-function-description"
}

variable "environment" {
  description = "A set of key/value environment variables for Yandex Cloud Function from tf-module"
  type        = map(string)
  default = {
    "name"    = "John"
    "surname" = "Wick"
  }
}

variable "create_trigger" {
  description = <<EOF
    Create trigger for Cloud Function (true) or not (false).
    If `true` parameter `choosing_trigger_type` must not be empty string.
    If `false` trigger `yc_trigger` will not be created for Cloud Function.
  EOF
  type        = bool
  default     = false
}
