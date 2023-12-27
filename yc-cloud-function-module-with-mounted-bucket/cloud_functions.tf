resource "yandex_function" "test_function_s3" {
  name               = "yc-function-example-s3"
  description        = "this is the yc cloud function for tf-module with mounted s3 bucket"
  user_hash          = "yc-defined-string-for-tf-module-s3" # User-defined string for current function version. User must change this string any times when function changed. Function will be updated when hash is changed.
  runtime            = var.runtime
  entrypoint         = var.entrypoint
  memory             = var.memory
  execution_timeout  = var.execution_timeout
  service_account_id = var.default_service_account_id
  tags               = ["yc_tag"]

  content {
    zip_filename = "handler.zip"
  }

  storage_mounts {
    mount_point_name = "yc-module-mount-point"
    bucket = "cloud-func-module-bucket"
    prefix = ""
    read_only = "true"
  }
  # loggroup_id = "${yandex_logging_group.yc_log_group.id}"
}

resource "yandex_function_trigger" "yc_trigger_s3" {
  name        = "yc-function-trigger-with-s3"
  description = "this is the yc cloud function trigger for tf-module with mounted s3 bucket"
  timer {
    cron_expression = var.cron_expression
  }
  function {
    id = "${yandex_function.test_function_s3.id}"
    service_account_id = var.default_service_account_id
  }
}

resource "yandex_function_iam_binding" "function_iam_s3" {
  function_id = "${yandex_function.test_function_s3.id}"
  role        = var.func_iam_binding

  members = [
    "system:allUsers",
  ]
}