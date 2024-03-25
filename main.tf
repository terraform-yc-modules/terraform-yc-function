data "yandex_client_config" "client" {}

locals {
  folder_id = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
  iam_defaults = {
    service_account_name = "function-service-account-${random_string.unique_id.result}"
  }
  create_sa = var.use_existing_sa
}

resource "yandex_resourcemanager_folder_iam_member" "cloud_func_editor" {
  count     = var.choosing_trigger_type == "object_storage" ? 1 : 0
  folder_id = local.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.default_cloud_function_sa[0].id}"
}

resource "yandex_iam_service_account_static_access_key" "cloud_func_static_key" {
  count              = var.choosing_trigger_type == "object_storage" ? 1 : 0
  service_account_id = yandex_iam_service_account.default_cloud_function_sa[0].id
  description        = "static access key for object storage"
}

resource "yandex_storage_bucket" "cloud_func_bucket" {
  count      = var.choosing_trigger_type == "object_storage" ? 1 : 0
  access_key = yandex_iam_service_account_static_access_key.cloud_func_static_key[0].access_key
  secret_key = yandex_iam_service_account_static_access_key.cloud_func_static_key[0].secret_key
  bucket     = "bucket-cloud-func-${random_string.unique_id.result}"
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
  count       = var.choosing_trigger_type == "logging" ? 1 : 0
  name        = "yc-logging-group-${random_string.unique_id.result}"
  description = "this is the yc logging group for tf-module"
}

resource "yandex_function" "yc_function" {
  name               = "yc-function-example-ymq-${random_string.unique_id.result}"
  description        = "this is the yc cloud function for tf-module with ymq"
  user_hash          = var.user_hash
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
    for_each = var.choosing_trigger_type == "logging" ? compact([try(yandex_logging_group.yc_log_group[0].id, null)]) : []
    content {
      group_id       = logging.value
      resource_types = ["serverless.function"]
      resource_ids   = [yandex_function.yc_function.id]
      levels         = ["INFO"]
      batch_cutoff   = 1
      batch_size     = 1
    }
  }

  dynamic "timer" {
    for_each = var.choosing_trigger_type == "timer" ? [compact([try(yandex_function.yc_function.id, null)])] : []
    content {
      cron_expression = var.cron_expression
    }
  }

  dynamic "object_storage" {
    for_each = var.choosing_trigger_type == "object_storage" ? [compact([try(yandex_function.yc_function.id, null)])] : []
    content {
      bucket_id    = yandex_storage_bucket.cloud_func_bucket[0].id
      create       = true
      update       = true
      delete       = true
      batch_cutoff = 1
      batch_size   = 1
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
