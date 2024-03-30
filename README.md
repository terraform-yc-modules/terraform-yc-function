# Cloud Function Terraform Module for Yandex.Cloud

## Features

- Create Cloud Function with scaling policy and different trigger types


## Cloud Function Definition

```
resource "yandex_function" "yc_function" {
  name               = "yc-function-example-ymq-${random_string.unique_id.result}"
  description        = "this is the yc cloud function for tf-module with ymq"
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
}
```

## Cloud Function Scaling Policy Definition

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

```
resource "yandex_function_trigger" "yc_trigger" {
  name        = "yc-function-trigger-${random_string.unique_id.result}"
  description = "this is the yc cloud function trigger with cloud logging"

  dynamic "logging" {
    for_each = var.choosing_trigger_type == "logging" ? compact([try(yandex_function.yc_function.id, null)]) : []
    content {
      group_id = var.logging.group_id
      resource_types = var.logging.resource_types
      levels = var.logging.levels
      batch_cutoff = var.logging.batch_cutoff
      batch_size = var.logging.batch_size
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
      queue_id = var.message_queue.queue_id
      service_account_id = local.create_sa ? var.existing_service_account_id : yandex_iam_service_account.default_cloud_function_sa[0].id
      batch_cutoff = var.message_queue.batch_cutoff
      batch_size = var.message_queue.batch_size
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
  tags = ["yc_tag"]

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
| <a name="provider_random"></a> [random](#provider\_random) | 3.6.0 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.11.1 |
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | 0.112.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [random_string.unique_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [time_sleep.wait_for_iam](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [yandex_function.yc_function](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/function) | resource |
| [yandex_function_scaling_policy.yc_scaling_policy](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/function_scaling_policy) | resource |
| [yandex_function_trigger.yc_trigger](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/function_trigger) | resource |
| [yandex_iam_service_account.default_cloud_function_sa](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/iam_service_account) | resource |
| [yandex_resourcemanager_folder_iam_binding.editor](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/resourcemanager_folder_iam_binding) | resource |
| [yandex_resourcemanager_folder_iam_binding.invoker](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/resourcemanager_folder_iam_binding) | resource |
| [yandex_client_config.client](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_choosing_trigger_type"></a> [choosing\_trigger\_type](#input\_choosing\_trigger\_type) | Choosing type for cloud function trigger | `string` | `"logging"` | no |
| <a name="input_entrypoint"></a> [entrypoint](#input\_entrypoint) | Entrypoint for Yandex Cloud Function. | `string` | `"handler.sh"` | no |
| <a name="input_execution_timeout"></a> [execution\_timeout](#input\_execution\_timeout) | Execution timeout in seconds for Yandex Cloud Function. | `number` | `10` | no |
| <a name="input_existing_service_account_id"></a> [existing\_service\_account\_id](#input\_existing\_service\_account\_id) | Existing IAM service account id. | `string` | `null` | no |
| <a name="input_existing_service_account_name"></a> [existing\_service\_account\_name](#input\_existing\_service\_account\_name) | Existing IAM service account name. | `string` | `null` | no |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id) | The ID of the folder that the Cloud Function belongs to. | `string` | `null` | no |
| <a name="input_logging"></a> [logging](#input\_logging) | Trigger type of logging. | <pre>object({<br>    group_id       = string<br>    resource_types = list(string)<br>    levels         = list(string)<br>    batch_cutoff   = number<br>    batch_size     = number<br>  })</pre> | <pre>{<br>  "batch_cutoff": 1,<br>  "batch_size": 1,<br>  "group_id": "e23moaejmq8m74tssfu9",<br>  "levels": [<br>    "INFO"<br>  ],<br>  "resource_types": [<br>    "serverless.function"<br>  ]<br>}</pre> | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory in megabytes for Yandex Cloud Function. | `number` | `128` | no |
| <a name="input_message_queue"></a> [message\_queue](#input\_message\_queue) | Trigger type of message queue. | <pre>object({<br>    queue_id           = string<br>    service_account_id = string<br>    batch_cutoff       = number<br>    batch_size         = number<br>    visibility_timeout = number<br>  })</pre> | <pre>{<br>  "batch_cutoff": 1,<br>  "batch_size": 1,<br>  "queue_id": "yrn:yc:ymq:ru-central1:b1gfl7u3a9ahaamt3ore:anana",<br>  "service_account_id": "ajeaebn6c3kfoekg9h3b",<br>  "visibility_timeout": 600<br>}</pre> | no |
| <a name="input_object_storage"></a> [object\_storage](#input\_object\_storage) | Trigger type of object storage. | <pre>object({<br>    bucket_id    = string<br>    create       = bool<br>    update       = bool<br>    delete       = bool<br>    batch_cutoff = number<br>    batch_size   = number<br>  })</pre> | <pre>{<br>  "batch_cutoff": 1,<br>  "batch_size": 1,<br>  "bucket_id": "yandex-cloud-nnn",<br>  "create": true,<br>  "delete": true,<br>  "update": true<br>}</pre> | no |
| <a name="input_policy"></a> [policy](#input\_policy) | List definition for Yandex Cloud Function scaling policies. | `map(any)` | <pre>{<br>  "tag": "$latest",<br>  "zone_instances_limit": 3,<br>  "zone_requests_limit": 100<br>}</pre> | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Runtime for Yandex Cloud Function. | `string` | `"bash-2204"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for Cloud Function. | `list(string)` | <pre>[<br>  "yc_tag"<br>]</pre> | no |
| <a name="input_timer"></a> [timer](#input\_timer) | Trigger type of timer. | <pre>object({<br>    cron_expression = string<br>  })</pre> | <pre>{<br>  "cron_expression": "*/15 * ? * * *"<br>}</pre> | no |
| <a name="input_use_existing_sa"></a> [use\_existing\_sa](#input\_use\_existing\_sa) | Use existing service accounts (true) or not (false).<br>    If `true` parameters `existing_service_account_id` must be set. | `bool` | `false` | no |
| <a name="input_user_hash"></a> [user\_hash](#input\_user\_hash) | User-defined string for current function version.<br>    User must change this string any times when function changed. <br>    Function will be updated when hash is changed." | `string` | `"yc-defined-string-for-tf-module"` | no |
| <a name="input_zip_filename"></a> [zip\_filename](#input\_zip\_filename) | Filename to zip archive for the version. | `string` | `"../../handler.zip"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
