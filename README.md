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
  name               = coalesce(var.yc_function_name, "yc-function-example-${random_string.unique_id.result}")
  description        = coalesce(var.yc_function_description, "Cloud function from tf-module terraform-yc-function with scaling policy and specific trigger type yc-function-trigger.")
  user_hash          = var.user_hash
  runtime            = var.runtime
  entrypoint         = var.entrypoint
  memory             = var.memory
  execution_timeout  = var.execution_timeout
  service_account_id = local.create_sa ? var.existing_service_account_id : yandex_iam_service_account.default_cloud_function_sa[0].id
  tags               = var.tags
  environment        = var.environment

  content {
    zip_filename = var.zip_filename
  }

  log_options {
    log_group_id = coalesce(var.existing_log_group_id, try(yandex_logging_group.default_log_group[0].id, ""))
    min_level    = var.min_level
  }

  dynamic "storage_mounts" {
    for_each = var.mount_bucket != true ? [] : tolist(1)
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
    for_each = var.use_async_invocation != true ? [] : tolist(1)
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
      tag                  = policy.value.tag
      zone_instances_limit = policy.value.zone_instances_limit
      zone_requests_limit  = policy.value.zone_requests_limit
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
- you can optionally create trigger for Cloud Function using variable `create_trigger`

```
resource "yandex_function_trigger" "yc_trigger" {
  count       = var.create_trigger ? 1 : 0
  name        = "yc-function-trigger-${random_string.unique_id.result}"
  description = "Specific cloud function trigger type yc-function-trigger for cloud function yc-function-example."

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

  # storage_mounts = {
  #   mount_point_name = "yc-function"
  #   bucket           = "yandex-cloud-nnn"
  # }

  # Cloud Function Scaling Policy Definition
  scaling_policy = [{
    tag                  = "yc_tag"
    zone_instances_limit = 20
    zone_requests_limit  = 20
  }]

  # Cloud Function Trigger Definition
  choosing_trigger_type = "" # "logging"

  logging = {
    group_id     = "e23moaejmq8m74tssfu9"
    batch_cutoff = 1
    batch_size   = 1
  }

  # timer = {}

  # object_storage = {
  #   bucket_id    = "yandex-cloud-nnn"
  #   batch_cutoff = 1
  #   batch_size   = 1
  # }

  # message_queue = {
  #   queue_id     = "yrn:yc:ymq:ru-central1:b1gfl7u3a9ahaamt3ore:anana"
  #   batch_cutoff = 1
  #   batch_size   = 1
  # }
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
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | > 3.3 |
| <a name="requirement_time"></a> [time](#requirement\_time) | > 0.9 |
| <a name="requirement_yandex"></a> [yandex](#requirement\_yandex) | >= 0.107.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.2 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.11.2 |
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | 0.123.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [random_string.unique_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [time_sleep.wait_for_iam](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [yandex_function.yc_function](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/function) | resource |
| [yandex_function_iam_binding.function_iam](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/function_iam_binding) | resource |
| [yandex_function_scaling_policy.yc_scaling_policy](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/function_scaling_policy) | resource |
| [yandex_function_trigger.yc_trigger](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/function_trigger) | resource |
| [yandex_iam_service_account.default_cloud_function_sa](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/iam_service_account) | resource |
| [yandex_lockbox_secret.yc_secret](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lockbox_secret) | resource |
| [yandex_lockbox_secret_version.yc_version](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/lockbox_secret_version) | resource |
| [yandex_logging_group.default_log_group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/logging_group) | resource |
| [yandex_resourcemanager_folder_iam_binding.editor](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/resourcemanager_folder_iam_binding) | resource |
| [yandex_resourcemanager_folder_iam_binding.invoker](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/resourcemanager_folder_iam_binding) | resource |
| [yandex_resourcemanager_folder_iam_binding.lockbox_payload_viewer](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/resourcemanager_folder_iam_binding) | resource |
| [yandex_client_config.client](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_choosing_trigger_type"></a> [choosing\_trigger\_type](#input\_choosing\_trigger\_type) | Choosing type for cloud function trigger. | `string` | n/a | yes |
| <a name="input_create_trigger"></a> [create\_trigger](#input\_create\_trigger) | Create trigger for Cloud Function (true) or not (false).<br>    If `true` parameter `choosing_trigger_type` must not be empty string.<br>    If `false` trigger `yc_trigger` will not be created for Cloud Function. | `bool` | `false` | no |
| <a name="input_entrypoint"></a> [entrypoint](#input\_entrypoint) | Entrypoint for cloud function yc-function-example. | `string` | `"handler.sh"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | A set of key/value environment variables for Yandex Cloud Function from tf-module | `map(string)` | <pre>{<br>  "name": "John",<br>  "surname": "Wick"<br>}</pre> | no |
| <a name="input_environment_variable"></a> [environment\_variable](#input\_environment\_variable) | Function's environment variable in which secret's value will be stored. | `string` | `"ENV_VARIABLE"` | no |
| <a name="input_execution_timeout"></a> [execution\_timeout](#input\_execution\_timeout) | Execution timeout in seconds for cloud function yc-function-example. | `number` | `10` | no |
| <a name="input_existing_log_group_id"></a> [existing\_log\_group\_id](#input\_existing\_log\_group\_id) | Existing logging group id. | `string` | `null` | no |
| <a name="input_existing_service_account_id"></a> [existing\_service\_account\_id](#input\_existing\_service\_account\_id) | Existing IAM service account id. | `string` | `null` | no |
| <a name="input_existing_service_account_name"></a> [existing\_service\_account\_name](#input\_existing\_service\_account\_name) | Existing IAM service account name. | `string` | `null` | no |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id) | The ID of the folder that the cloud function yc-function-example belongs to. | `string` | `null` | no |
| <a name="input_lockbox_secret_key"></a> [lockbox\_secret\_key](#input\_lockbox\_secret\_key) | Lockbox secret key for cloud function yc-function-example. | `string` | n/a | yes |
| <a name="input_lockbox_secret_value"></a> [lockbox\_secret\_value](#input\_lockbox\_secret\_value) | Lockbox secret value for cloud function yc-function-example. | `string` | n/a | yes |
| <a name="input_logging"></a> [logging](#input\_logging) | Trigger type of logging. | <pre>object({<br>    group_id       = string<br>    resource_ids   = optional(list(string))<br>    resource_types = optional(list(string), ["serverless.function"])<br>    levels         = optional(list(string), ["INFO"])<br>    batch_cutoff   = number<br>    batch_size     = number<br>    stream_names   = optional(list(string))<br>  })</pre> | <pre>{<br>  "batch_cutoff": 1,<br>  "batch_size": 1,<br>  "group_id": null<br>}</pre> | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory in megabytes for cloud function yc-function-example. | `number` | `128` | no |
| <a name="input_message_queue"></a> [message\_queue](#input\_message\_queue) | Trigger type of message queue. | <pre>object({<br>    queue_id           = string<br>    service_account_id = optional(string)<br>    batch_cutoff       = number<br>    batch_size         = number<br>    visibility_timeout = optional(number, 600)<br>  })</pre> | <pre>{<br>  "batch_cutoff": 1,<br>  "batch_size": 1,<br>  "queue_id": null,<br>  "service_account_id": null<br>}</pre> | no |
| <a name="input_min_level"></a> [min\_level](#input\_min\_level) | Minimal level of logging for cloud function yc-function-example. | `string` | `"ERROR"` | no |
| <a name="input_mount_bucket"></a> [mount\_bucket](#input\_mount\_bucket) | Mount bucket (true) or not (false). If `true` section `storage_mounts{}` should be defined. | `bool` | `false` | no |
| <a name="input_network_id"></a> [network\_id](#input\_network\_id) | Cloud function's network id for VPC integration. | `string` | `null` | no |
| <a name="input_object_storage"></a> [object\_storage](#input\_object\_storage) | Trigger type of object storage. | <pre>object({<br>    bucket_id    = string<br>    prefix       = optional(string)<br>    suffix       = optional(string)<br>    create       = optional(bool, true)<br>    update       = optional(bool, true)<br>    delete       = optional(bool, true)<br>    batch_cutoff = number<br>    batch_size   = number<br>  })</pre> | <pre>{<br>  "batch_cutoff": 1,<br>  "batch_size": 1,<br>  "bucket_id": null<br>}</pre> | no |
| <a name="input_public_access"></a> [public\_access](#input\_public\_access) | Making cloud function public (true) or not (false). | `bool` | `false` | no |
| <a name="input_retries_count"></a> [retries\_count](#input\_retries\_count) | Maximum number of retries for async invocation. | `number` | `3` | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Runtime for cloud function yc-function-example. | `string` | `"bash-2204"` | no |
| <a name="input_scaling_policy"></a> [scaling\_policy](#input\_scaling\_policy) | List of scaling policies for cloud function yc-function-example. | <pre>list(object({<br>    tag                  = string<br>    zone_instances_limit = number<br>    zone_requests_limit  = number<br>  }))</pre> | n/a | yes |
| <a name="input_storage_mounts"></a> [storage\_mounts](#input\_storage\_mounts) | Mounting s3 bucket. | <pre>object({<br>    mount_point_name = string<br>    bucket           = string<br>    prefix           = optional(string)<br>    read_only        = optional(bool, true)<br>  })</pre> | <pre>{<br>  "bucket": null,<br>  "mount_point_name": "yc-function"<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | List of tags for cloud function yc-function-example. | `list(string)` | <pre>[<br>  "yc_tag"<br>]</pre> | no |
| <a name="input_timer"></a> [timer](#input\_timer) | Trigger type of timer. | <pre>object({<br>    cron_expression = optional(string, "*/30 * ? * * *")<br>    payload         = optional(string)<br>  })</pre> | <pre>{<br>  "cron_expression": "*/5 * ? * * *",<br>  "payload": null<br>}</pre> | no |
| <a name="input_use_async_invocation"></a> [use\_async\_invocation](#input\_use\_async\_invocation) | Use asynchronous invocation to message queue (true) or not (false). If `true`, parameters `ymq_success_target` and `ymq_failure_target` must be set. | `bool` | `false` | no |
| <a name="input_use_existing_log_group"></a> [use\_existing\_log\_group](#input\_use\_existing\_log\_group) | Use existing logging group (true) or not (false).<br>    If `true` parameters `existing_log_group_id` must be set. | `bool` | `false` | no |
| <a name="input_use_existing_sa"></a> [use\_existing\_sa](#input\_use\_existing\_sa) | Use existing service accounts (true) or not (false).<br>    If `true` parameters `existing_service_account_id` must be set. | `bool` | `false` | no |
| <a name="input_user_hash"></a> [user\_hash](#input\_user\_hash) | User-defined string for current function version.<br>    User must change this string any times when function changed. <br>    Function will be updated when hash is changed." | `string` | `"yc-defined-string-for-tf-module"` | no |
| <a name="input_yc_function_description"></a> [yc\_function\_description](#input\_yc\_function\_description) | Custom Cloud Function description from tf-module | `string` | `"yc-custom-function-description"` | no |
| <a name="input_yc_function_name"></a> [yc\_function\_name](#input\_yc\_function\_name) | Custom Cloud Function name from tf-module | `string` | `"yc-custom-function-name"` | no |
| <a name="input_ymq_failure_target"></a> [ymq\_failure\_target](#input\_ymq\_failure\_target) | Target for unsuccessful async invocation. | `string` | `null` | no |
| <a name="input_ymq_success_target"></a> [ymq\_success\_target](#input\_ymq\_success\_target) | Target for successful async invocation. | `string` | `null` | no |
| <a name="input_zip_filename"></a> [zip\_filename](#input\_zip\_filename) | Filename to zip archive for the version of cloud function's code. | `string` | `"../../handler.zip"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_function_id"></a> [function\_id](#output\_function\_id) | Yandex cloud function ID. |
| <a name="output_function_name"></a> [function\_name](#output\_function\_name) | Yandex cloud function name. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
