# Cloud Function Terraform Module for Yandex.Cloud

## Features

- Create Cloud Function with forwarding logs to Cloud Logging


## Cloud Function Definition

```
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
```

## Cloud Function Scaling Policy Definition

```
resource "yandex_function_scaling_policy" "my_scaling_policy" {
  function_id = yandex_function.yc_function.id

  policy {
    tag = var.policy.tag
    zone_instances_limit = var.policy.zone_instances_limit
    zone_requests_limit = var.policy.zone_requests_limit
  }
}
```

## Cloud Function Trigger Definition

```
resource "yandex_function_trigger" "yc_trigger" {
  name        = "yc-function-trigger-${random_string.unique_id.result}"
  description = "this is the yc cloud function trigger with cloud logging"
  dynamic "logging" {
    for_each = var.create_logging_group ? compact([try(yandex_logging_group.yc_log_group[0].id, null)]) : []
    content {
      group_id = logging.value
      resource_types = ["serverless.function"]
      resource_ids = [yandex_function.yc_function.id]
      levels = ["INFO"]
      batch_cutoff   = 1
      batch_size     = 1
    }
  }
  function {
    id = yandex_function.yc_function.id
    service_account_id = yandex_iam_service_account.default_cloud_function_sa[0].id
  }
}
```

### Example Usage

```hcl-terraform
module "cloud_function" {
  source = "../../"

  # Cloud Function Definition
  zip_filename = "../../handler.zip"
  runtime = "bash-2204"
  entrypoint = "handler.sh"
  memory = 128
  execution_timeout = 10

  # Cloud Function Scaling Policy Definition
  policy = {
    tag = "$latest"
    zone_instances_limit = 3
    zone_requests_limit  = 100
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
export TF_VAR_YC_KEY="yc-key"
export TF_VAR_YC_VALUE="yc-value"
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
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | 0.112.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [random_string.unique_id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string) | resource |
| [yandex_function.yc_function](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/function) | resource |
| [yandex_function_scaling_policy.my_scaling_policy](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/function_scaling_policy) | resource |
| [yandex_function_trigger.yc_trigger](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/function_trigger) | resource |
| [yandex_iam_service_account.default_cloud_function_sa](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/iam_service_account) | resource |
| [yandex_iam_service_account_static_access_key.cloud_func_static_key](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/iam_service_account_static_access_key) | resource |
| [yandex_logging_group.yc_log_group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/logging_group) | resource |
| [yandex_resourcemanager_folder_iam_binding.invoker](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/resourcemanager_folder_iam_binding) | resource |
| [yandex_resourcemanager_folder_iam_member.cloud_func_editor](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/resourcemanager_folder_iam_member) | resource |
| [yandex_storage_bucket.cloud_func_bucket](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/storage_bucket) | resource |
| [yandex_client_config.client](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/data-sources/client_config) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_choosing_trigger_type"></a> [choosing\_trigger\_type](#input\_choosing\_trigger\_type) | Choosing type for cloud function trigger | `string` | `"logging"` | no |
| <a name="input_cron_expression"></a> [cron\_expression](#input\_cron\_expression) | value | `string` | `"*/15 * ? * * *"` | no |
| <a name="input_entrypoint"></a> [entrypoint](#input\_entrypoint) | Entrypoint for Yandex Cloud Function. | `string` | `"handler.sh"` | no |
| <a name="input_execution_timeout"></a> [execution\_timeout](#input\_execution\_timeout) | Execution timeout in seconds for Yandex Cloud Function. | `number` | `10` | no |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id) | The ID of the folder that the Cloud Function belongs to. | `string` | `null` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory in megabytes for Yandex Cloud Function. | `number` | `128` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | List definition for Yandex Cloud Function scaling policies. | `map(any)` | <pre>{<br>  "tag": "$latest",<br>  "zone_instances_limit": 3,<br>  "zone_requests_limit": 100<br>}</pre> | no |
| <a name="input_runtime"></a> [runtime](#input\_runtime) | Runtime for Yandex Cloud Function. | `string` | `"bash-2204"` | no |
| <a name="input_service_account_name"></a> [service\_account\_name](#input\_service\_account\_name) | IAM service account name. | `string` | `"function-service-account"` | no |
| <a name="input_use_existing_sa"></a> [use\_existing\_sa](#input\_use\_existing\_sa) | Use existing service accounts (true) or not (false). | `bool` | `false` | no |
| <a name="input_user_hash"></a> [user\_hash](#input\_user\_hash) | User-defined string for current function version.<br>    User must change this string any times when function changed. <br>    Function will be updated when hash is changed." | `string` | `"yc-defined-string"` | no |
| <a name="input_zip_filename"></a> [zip\_filename](#input\_zip\_filename) | Filename to zip archive for the version. | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
