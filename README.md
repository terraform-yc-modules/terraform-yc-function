# Cloud Function Terraform Module for Yandex.Cloud

## Features

- Create Cloud Function with asynchronous invocations and forwarding logs to Cloud Logging
- Create Cloud Function with lockbox secret
- Create Cloud Function with mounted bucket


## Cloud Function definition

## Configure Terraform for Yandex Cloud

- Install [YC CLI](https://cloud.yandex.com/docs/cli/quickstart)
- Add environment variables for terraform authentication in Yandex Cloud

```
export YC_TOKEN=$(yc iam create-token)
export YC_CLOUD_ID=$(yc config get cloud-id)
export YC_FOLDER_ID=$(yc config get folder-id)
export TF_VAR_YC_VALUE="yc-value"
export TF_VAR_YC_ACCESS_KEY=<access-key>
export TF_VAR_YC_SECRET_KEY=<secret-key>
```

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_yandex"></a> [yandex](#requirement\_yandex) | >= 0.98 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | >= 0.98.0 |


## Modules
```
module.cloud_function_module_with_lockbox_secret 
module.cloud_function_module_with_async_invocation_to_ymq
module.cloud_function_module_with_mounted_bucket
```



terraform apply -target=module.cloud_function_module_with_lockbox_secret


terraform apply -target=module.cloud_function_module_with_async_invocation_to_ymq

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

