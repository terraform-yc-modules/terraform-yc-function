data "yandex_client_config" "client" {}

locals {
  folder_id = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
}

resource "time_sleep" "wait_for_iam" {
  create_duration = "5s"
  depends_on = [
    yandex_logging_group.yc_log_group,
    yandex_function.yc_function,
    yandex_function_trigger.yc_trigger_ymq,
    yandex_function_iam_binding.function_iam_ymq, 
    yandex_message_queue.yc_queue,
    yandex_message_queue.yc_dead_letter_queue
  ]
}

resource "yandex_logging_group" "yc_log_group" {
  name      = "yc-logging-group-${random_string.unique_id.result}"
  description = "this is the yc logging group for tf-module"
}

resource "yandex_message_queue" "yc_queue" {
  name                        = "yc-queue-${random_string.unique_id.result}"
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  receive_wait_time_seconds   = var.receive_wait_time_seconds
  message_retention_seconds   = var.message_retention_seconds
  redrive_policy              = jsonencode({
    deadLetterTargetArn = yandex_message_queue.yc_dead_letter_queue.arn
    maxReceiveCount     = var.maxReceiveCount
  })
  access_key = var.YC_ACCESS_KEY
  secret_key = var.YC_SECRET_KEY
}

resource "yandex_message_queue" "yc_dead_letter_queue" {
  name                        = "yc-dead-letter-queue-${random_string.unique_id.result}"
  access_key = var.YC_ACCESS_KEY
  secret_key = var.YC_SECRET_KEY
}


resource "yandex_lockbox_secret" "yc_secret" {
  name = "yc-secret-${random_string.unique_id.result}"
}

resource "yandex_lockbox_secret_version" "yc_version" {
  secret_id = yandex_lockbox_secret.yc_secret.id
  entries {
    key        = var.lockbox_secret_key
    text_value = var.YC_VALUE
  }
}
resource "yandex_function" "yc_function" {
  name               = "yc-function-example-ymq-${random_string.unique_id.result}"
  description        = "this is the yc cloud function for tf-module with ymq"
  user_hash          = "yc-defined-string-for-tf-module" # User-defined string for current function version. User must change this string any times when function changed. Function will be updated when hash is changed.
  runtime            = var.runtime
  entrypoint         = var.entrypoint
  memory             = var.memory
  execution_timeout  = var.execution_timeout
  service_account_id = var.default_function_service_account_id
  tags               = ["yc_tag"]

  secrets {
    id = "${yandex_lockbox_secret.yc_secret.id}"
    version_id = "${yandex_lockbox_secret_version.yc_version.id}"
    key = var.lockbox_secret_key
    environment_variable = "ENV_VARIABLE"
  }

  content {
    zip_filename = var.zip_filename
  }

  async_invocation {
    retries_count = var.retries_count
    service_account_id = var.default_invoker_service_account_id

    ymq_failure_target {
      arn = yandex_message_queue.yc_dead_letter_queue.arn
      service_account_id = var.default_ymq_writer_service_account_id
    }
    ymq_success_target {
      arn = yandex_message_queue.yc_queue.arn
      service_account_id = var.default_ymq_writer_service_account_id
    }
  }
  log_options {
    log_group_id = "${yandex_logging_group.yc_log_group.id}"
    min_level = "DEBUG"
  }
}

resource "yandex_function_trigger" "yc_trigger_ymq" {
  name        = "yc-function-trigger-${random_string.unique_id.result}"
  description = "this is the yc cloud function trigger for tf-module with ymq"
  timer {
    cron_expression = var.cron_expression
  }
  function {
    id = "${yandex_function.yc_function.id}"
    service_account_id = var.default_invoker_service_account_id
  }
}

resource "yandex_function_iam_binding" "function_iam_ymq" {
  function_id = "${yandex_function.yc_function.id}"
  role        = var.func_iam_binding

  members = [
    "system:allUsers",
  ]
}