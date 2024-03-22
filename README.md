# Cloud Function Terraform Module for Yandex.Cloud

## Features

- Create Cloud Function with asynchronous invocations, with lockbox secret and forwarding logs to Cloud Logging


## Cloud Function definition

```
resource "yandex_function" "yc_function" {
  name               = "yc-function-example-ymq-${random_string.unique_id.result}"
  description        = "this is the yc cloud function for tf-module with ymq"
  user_hash          = "yc-defined-string-for-tf-module" # User-defined string for current function version. User must change this string any times when function changed. Function will be updated when hash is changed.
  runtime            = var.runtime
  entrypoint         = var.entrypoint
  memory             = var.memory
  execution_timeout  = var.execution_timeout
  service_account_id = var.default_function_service_account_id
  tags               = ["yc_tag"]

  secrets {
    id = "${yandex_lockbox_secret.yc_secret.id}"
    version_id = "${yandex_lockbox_secret_version.yc_version.id}"
    key = var.lockbox_secret_key
    environment_variable = "ENV_VARIABLE"
  }

  content {
    zip_filename = var.zip_filename
  }

  async_invocation {
    retries_count = var.retries_count
    service_account_id = var.default_invoker_service_account_id

    ymq_failure_target {
      arn = yandex_message_queue.yc_dead_letter_queue.arn
      service_account_id = var.default_ymq_writer_service_account_id
    }
    ymq_success_target {
      arn = yandex_message_queue.yc_queue.arn
      service_account_id = var.default_ymq_writer_service_account_id
    }
  }
  log_options {
    log_group_id = "${yandex_logging_group.yc_log_group.id}"
    min_level = "DEBUG"
  }
}
```


### Example Usage

```hcl-terraform

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