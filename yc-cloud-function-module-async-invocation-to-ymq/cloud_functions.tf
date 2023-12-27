resource "yandex_function" "test_function_ymq" {
  name               = "yc-function-example-ymq"
  description        = "this is the yc cloud function for tf-module with ymq"
  user_hash          = "yc-defined-string-for-tf-module-ymq" # User-defined string for current function version. User must change this string any times when function changed. Function will be updated when hash is changed.
  runtime            = var.runtime
  entrypoint         = var.entrypoint
  memory             = var.memory
  execution_timeout  = var.execution_timeout
  service_account_id = "${yandex_iam_service_account.yc_sa.id}"
  tags               = ["yc_tag"]

  content {
    zip_filename = "handler.zip"
  }

  async_invocation {
    retries_count = var.retries_count
    service_account_id = var.default_service_account_id

    ymq_failure_target {
      arn = yandex_message_queue.yc_dead_letter_queue.arn
      service_account_id = var.default_service_account_id
    }
    ymq_success_target {
      arn = yandex_message_queue.yc_queue.arn
      service_account_id = var.default_service_account_id
    }
  }
  # loggroup_id = "${yandex_logging_group.yc_log_group.id}"
}

resource "yandex_function_trigger" "yc_trigger_ymq" {
  name        = "yc-function-trigger-with-ymq"
  description = "this is the yc cloud function trigger for tf-module with ymq"
  timer {
    cron_expression = var.cron_expression
  }
  function {
    id = "${yandex_function.test_function_ymq.id}"
    service_account_id = var.default_service_account_id
  }
}

resource "yandex_function_iam_binding" "function_iam_ymq" {
  function_id = "${yandex_function.test_function_ymq.id}"
  role        = var.func_iam_binding

  members = [
    "system:allUsers",
  ]
}