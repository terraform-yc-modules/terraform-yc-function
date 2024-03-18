# Cloud Function Terraform Module for Yandex.Cloud

## Features

- Create Cloud Function with asynchronous invocations, with lockbox secret and forwarding logs to Cloud Logging


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