data "yandex_client_config" "client" {}

locals {
  folder_id = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
  iam_defaults = {
    service_account_name = "function-service-account-${random_string.unique_id.result}"
  }
  create_sa        = var.use_existing_sa && var.existing_service_account_id != null ? true : false
  create_log_group = var.use_existing_log_group && var.existing_log_group_id != null ? true : false
}

resource "time_sleep" "wait_for_iam" {
  create_duration = "5s"
  depends_on = [
    yandex_resourcemanager_folder_iam_binding.invoker,
    yandex_resourcemanager_folder_iam_binding.editor
  ]
}

resource "yandex_lockbox_secret" "yc_secret" {
  name = "yc-lockbox-secret-${random_string.unique_id.result}"
}

resource "yandex_lockbox_secret_version" "yc_version" {
  secret_id = yandex_lockbox_secret.yc_secret.id
  entries {
    key        = var.lockbox_secret_key
    text_value = var.lockbox_secret_value
  }
}

resource "yandex_logging_group" "default_log_group" {
  count     = local.create_log_group ? 0 : 1
  folder_id = local.folder_id
  name      = "yc-logging-group-${random_string.unique_id.result}"
}

resource "yandex_iam_service_account" "default_cloud_function_sa" {
  count     = local.create_sa ? 0 : 1
  folder_id = local.folder_id
  name      = try("${var.existing_service_account_name}-${random_string.unique_id.result}", local.iam_defaults.service_account_name)
}

resource "yandex_resourcemanager_folder_iam_binding" "invoker" {
  count     = local.create_sa ? 0 : 1
  folder_id = local.folder_id
  role      = "functions.functionInvoker"
  members = [
    "serviceAccount:${yandex_iam_service_account.default_cloud_function_sa[0].id}",
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  count     = local.create_sa ? 0 : 1
  folder_id = local.folder_id
  role      = "editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.default_cloud_function_sa[0].id}",
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "lockbox_payload_viewer" {
  folder_id = local.folder_id
  role      = "lockbox.payloadViewer"
  members = [
    "serviceAccount:${yandex_iam_service_account.default_cloud_function_sa[0].id}",
  ]
}

resource "yandex_function" "yc_function" {
  name               = "yc-function-example-${random_string.unique_id.result}"
  description        = "this is the yc cloud function for tf-module"
  user_hash          = var.user_hash
  runtime            = var.runtime
  entrypoint         = var.entrypoint
  memory             = var.memory
  execution_timeout  = var.execution_timeout
  service_account_id = local.create_sa ? var.existing_service_account_id : yandex_iam_service_account.default_cloud_function_sa[0].id
  tags               = var.tags

  content {
    zip_filename = var.zip_filename
  }

  log_options {
    log_group_id = coalesce(var.existing_log_group_id, try(yandex_logging_group.default_log_group[0].id, ""))
    min_level    = var.min_level
  }

  secrets {
    id                   = yandex_lockbox_secret.yc_secret.id
    version_id           = yandex_lockbox_secret_version.yc_version.id
    key                  = var.lockbox_secret_key
    environment_variable = var.environment_variable
  }
}

resource "yandex_function_trigger" "yc_trigger" {
  name        = "yc-function-trigger-${random_string.unique_id.result}"
  description = "this is the yc cloud function trigger with cloud logging"

  dynamic "logging" {
    for_each = var.choosing_trigger_type == "logging" ? compact([try(yandex_function.yc_function.id, null)]) : []
    content {
      group_id       = var.logging.group_id
      resource_types = var.logging.resource_types
      levels         = var.logging.levels
      batch_cutoff   = var.logging.batch_cutoff
      batch_size     = var.logging.batch_size
    }
  }

  dynamic "timer" {
    for_each = var.choosing_trigger_type == "timer" ? compact([try(yandex_function.yc_function.id, null)]) : []
    content {
      cron_expression = var.timer.cron_expression
    }
  }

  dynamic "object_storage" {
    for_each = var.choosing_trigger_type == "object_storage" ? compact([try(yandex_function.yc_function.id, null)]) : []
    content {
      bucket_id    = var.object_storage.bucket_id
      create       = var.object_storage.create
      update       = var.object_storage.update
      delete       = var.object_storage.delete
      batch_cutoff = var.object_storage.batch_cutoff
      batch_size   = var.object_storage.batch_size
    }
  }

  dynamic "message_queue" {
    for_each = var.choosing_trigger_type == "message_queue" ? compact([try(yandex_function.yc_function.id, null)]) : []
    content {
      queue_id           = var.message_queue.queue_id
      service_account_id = local.create_sa ? var.existing_service_account_id : yandex_iam_service_account.default_cloud_function_sa[0].id
      batch_cutoff       = var.message_queue.batch_cutoff
      batch_size         = var.message_queue.batch_size
      visibility_timeout = var.message_queue.visibility_timeout
    }
  }

  function {
    id                 = yandex_function.yc_function.id
    service_account_id = local.create_sa ? var.existing_service_account_id : yandex_iam_service_account.default_cloud_function_sa[0].id
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_binding.editor,
    yandex_resourcemanager_folder_iam_binding.invoker,
    time_sleep.wait_for_iam
  ]
}

resource "yandex_function_scaling_policy" "yc_scaling_policy" {
  function_id = yandex_function.yc_function.id
  policy {
    tag                  = var.policy.tag
    zone_instances_limit = var.policy.zone_instances_limit
    zone_requests_limit  = var.policy.zone_requests_limit
  }
}
