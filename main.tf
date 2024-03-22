data "yandex_client_config" "client" {}

locals {
  folder_id = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
  iam_defaults = {
    service_account_name = "function-service-account-${random_string.unique_id.result}"
  }
  create_sa = var.use_existing_sa
}

resource "yandex_iam_service_account" "default_cloud_function_sa" {
  count     = local.create_sa ? 0 : 1
  folder_id = local.folder_id
  name      = try("${var.service_account_name}-${random_string.unique_id.result}", local.iam_defaults.service_account_name)
}

resource "yandex_resourcemanager_folder_iam_binding" "invoker" {
  folder_id = local.folder_id
  role      = "serverless.functions.invoker"
  members = [
    "serviceAccount:${yandex_iam_service_account.default_cloud_function_sa[0].id}",
  ]
}

resource "yandex_logging_group" "yc_log_group" {
  count       = var.create_logging_group ? 1 : 0
  name        = "yc-logging-group-${random_string.unique_id.result}"
  description = "this is the yc logging group for tf-module"
}

resource "yandex_function" "yc_function" {
  name               = "yc-function-example-ymq-${random_string.unique_id.result}"
  description        = "this is the yc cloud function for tf-module with ymq"
  user_hash          = "yc-defined-string-for-tf-module" # User-defined string for current function version. User must change this string any times when function changed. Function will be updated when hash is changed.
  runtime            = var.runtime
  entrypoint         = var.entrypoint
  memory             = var.memory
  execution_timeout  = var.execution_timeout
  service_account_id = yandex_iam_service_account.default_cloud_function_sa[0].id
  tags               = ["yc_tag"]

  content {
    zip_filename = var.zip_filename
  }
}

resource "yandex_function_trigger" "yc_trigger" {
  name        = "yc-function-trigger-${random_string.unique_id.result}"
  description = "this is the yc cloud function trigger with cloud logging"
  dynamic "logging" {
    for_each = var.create_logging_group ? compact([try(yandex_logging_group.yc_log_group[0].id, null)]) : []
    content {
      group_id       = logging.value
      resource_types = ["serverless.function"]
      resource_ids   = [yandex_function.yc_function.id]
      levels         = ["INFO"]
      batch_cutoff   = 1
      batch_size     = 1
    }
  }
  function {
    id                 = yandex_function.yc_function.id
    service_account_id = yandex_iam_service_account.default_cloud_function_sa[0].id
  }
}

resource "yandex_function_scaling_policy" "my_scaling_policy" {
  function_id = yandex_function.yc_function.id

  policy {
    tag                  = var.policy.tag
    zone_instances_limit = var.policy.zone_instances_limit
    zone_requests_limit  = var.policy.zone_requests_limit
  }
}
