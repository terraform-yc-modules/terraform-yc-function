# Cloud Function Terraform Module for Yandex.Cloud

## Features

- Create cloud function with lockbox secret, list of scaling policies and specific trigger type. 
- Integration with VPC can be added to cloud function.
- Options for creating service account and/or logging group for the function.
- Mounting the bucket for cloud function.


## Cloud Function Definition
First, you need to define parameter `zip_filename` for the Cloud Function.

Notes:
- you can use existing `service_account_id` or create new SA with bindings
- you can use existing `log_group_id` or create new loggging group
- lockbox secret is used by default for the function
- you should use environment variables or tfvars-files to redefine `lockbox_secret_key` and `lockbox_secret_value`
- you should create NAT gateway first, if you'd like to try Cloud Function's VPC integration. Variable `network_id` should be not null
- you can mount S3 bucket to the function. Variable `mount_bucket` and section `storage_mounts` should be defined
- you can use asynchronous invocation to message queue for the Cloud Function. Variable `use_async_invocation` and `ymq_success_target`, `ymq_failure_target` must be defined.


```
resource "yandex_function" "yc_function" {
  name               = "yc-function-example-${random_string.unique_id.result}"
  description        = "YC Cloud Function"
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

  dynamic "storage_mounts" {
    for_each = var.mount_bucket == false ? [] : tolist(yandex_iam_service_account.default_cloud_function_sa[0].id)
    content {
      mount_point_name = var.storage_mounts.mount_point_name
      bucket           = var.storage_mounts.bucket
      prefix           = var.storage_mounts.prefix
      read_only        = var.storage_mounts.read_only
    }
  }
  connectivity {
    network_id = var.network_id != null ? var.network_id : ""
  }

  secrets {
    id                   = yandex_lockbox_secret.yc_secret.id
    version_id           = yandex_lockbox_secret_version.yc_version.id
    key                  = var.lockbox_secret_key
    environment_variable = var.environment_variable
  }

  dynamic "async_invocation" {
    for_each = var.use_async_invocation == false ? [] : [yandex_iam_service_account.default_cloud_function_sa[0].id]
    content {
      retries_count      = var.retries_count
      service_account_id = local.create_sa ? var.existing_service_account_id : yandex_iam_service_account.default_cloud_function_sa[0].id
      ymq_failure_target {
        service_account_id = local.create_sa ? var.existing_service_account_id : yandex_iam_service_account.default_cloud_function_sa[0].id
        arn                = var.ymq_failure_target
      }
      ymq_success_target {
        service_account_id = local.create_sa ? var.existing_service_account_id : yandex_iam_service_account.default_cloud_function_sa[0].id
        arn                = var.ymq_success_target
      }
    }
  }

  depends_on = [
    yandex_resourcemanager_folder_iam_binding.editor,
    yandex_resourcemanager_folder_iam_binding.invoker,
    yandex_resourcemanager_folder_iam_binding.lockbox_payload_viewer,
    time_sleep.wait_for_iam
  ]
}
```

## Cloud Function Scaling Policy Definition
Define the policy `tag`, `zone_instances_limit` and `zone_requests_limit`.

```
resource "yandex_function_scaling_policy" "yc_scaling_policy" {
  function_id = yandex_function.yc_function.id

  dynamic "policy" {
    for_each = var.scaling_policy
    content {
      tag = policy.value.tag
      zone_instances_limit = policy.value.zone_instances_limit
      zone_requests_limit = policy.value.zone_requests_limit
    }
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
  description = "YC Cloud Function Trigger"

  dynamic "logging" {
    for_each = var.choosing_trigger_type == "logging" ? [yandex_function.yc_function.id] : []
    content {
      group_id       = var.logging.group_id
      resource_types = var.logging.resource_types
      levels         = var.logging.levels
      batch_cutoff   = var.logging.batch_cutoff
      batch_size     = var.logging.batch_size
    }
  }

  dynamic "timer" {
    for_each = var.choosing_trigger_type == "timer" ? [yandex_function.yc_function.id] : []
    content {
      cron_expression = var.timer.cron_expression
    }
  }

  dynamic "object_storage" {
    for_each = var.choosing_trigger_type == "object_storage" ? [yandex_function.yc_function.id] : []
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
    for_each = var.choosing_trigger_type == "message_queue" ? [yandex_function.yc_function.id] : []
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
    yandex_resourcemanager_folder_iam_binding.lockbox_payload_viewer,
    time_sleep.wait_for_iam
  ]
}
```

### Example Usage

```hcl-terraform
module "cloud_function" {
  source = "../../"

  # Cloud Function Definition
  lockbox_secret_key   = var.lockbox_secret_key
  lockbox_secret_value = var.lockbox_secret_value

  zip_filename = "../../handler.zip"

  # Cloud Function Scaling Policy Definition
  scaling_policy = [{
    tag = "yc_tag"
    zone_instances_limit = 20
    zone_requests_limit = 20
  }]

  # Cloud Function Trigger Definition
  choosing_trigger_type = "logging"

  logging = {
    group_id     = "e23moaejmq8m74tssfu9"
    batch_cutoff = 1
    batch_size   = 1
  }
}
```

## Configure Terraform for Yandex Cloud

- Install [YC CLI](https://cloud.yandex.com/docs/cli/quickstart)
- Add environment variables for terraform authentication in Yandex Cloud

```
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
export TF_VAR_lockbox_secret_key=<yc-key>
export TF_VAR_lockbox_secret_value=<yc-value>
```


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
