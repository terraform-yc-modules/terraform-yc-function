# Cloud Function Terraform Module for Yandex.Cloud

## Features

- Create Cloud Function with lockbox secret, scaling policy and a trigger type


## Cloud Function Definition
First, you need to define list of parameters for the Cloud Function:
- zip_filename
- user_hash
- runtime
- entrypoint
- memory 
- execution_timeout
- tags

Notes:
- you can use existing `service_account_id` or create new SA with bindings
- you can use existing `log_group_id` or create new loggging group
- lockbox secret is used by default for the function
- you should use environment variables or tfvars-files to redefine `lockbox_secret_key` and `lockbox_secret_value`


```
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
    min_level = var.min_level
  }

  secrets {
    id = yandex_lockbox_secret.yc_secret.id
    version_id = yandex_lockbox_secret_version.yc_version.id
    key = var.lockbox_secret_key
    environment_variable = var.environment_variable
  }
}
```

## Cloud Function Scaling Policy Definition
Define the policy `tag`, `zone_instances_limit` and `zone_requests_limit`.

```
resource "yandex_function_scaling_policy" "yc_scaling_policy" {
  function_id = yandex_function.yc_function.id
  policy {
    tag                  = var.policy.tag
    zone_instances_limit = var.policy.zone_instances_limit
    zone_requests_limit  = var.policy.zone_requests_limit
  }
}
```

## Cloud Function Trigger Definition
Define parameter `choosing_trigger_type` to choose one of the trigger types:
- logging
- timer
- object_storage
- message_queue

Only one option is acceptable.

`choosing_trigger_type` can not have other options because of the validation condition.

Notes:
- you can use existing `service_account_id` or create new SA with bindings
- it's possible to change default values in variables for different trigger types

```
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
```

### Example Usage

```hcl-terraform
module "cloud_function" {
  source = "../../"

  # Cloud Function Definition
  zip_filename      = "../../handler.zip"
  user_hash         = "yc-defined-string-for-tf-module" # User-defined string for current function version. User must change this string any times when function changed. Function will be updated when hash is changed.
  runtime           = "bash-2204"
  entrypoint        = "handler.sh"
  memory            = 128
  execution_timeout = 10
  tags              = ["yc_tag"]

  # Cloud Function Scaling Policy Definition
  policy = {
    tag                  = "$latest"
    zone_instances_limit = 3
    zone_requests_limit  = 100
  }

  # Cloud Function Trigger Definition
  choosing_trigger_type = "message_queue"
}
```

## Configure Terraform for Yandex Cloud

- Install [YC CLI](https://cloud.yandex.com/docs/cli/quickstart)
- Add environment variables for terraform authentication in Yandex Cloud

```
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
```


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
