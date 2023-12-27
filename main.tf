module "cloud_function_module_with_lockbox_secret" {
  source       = "./yc-cloud-function-module-with-lockbox-secret"
  YC_VALUE     = var.YC_VALUE
  default_zone = "ru-central1-b"

  runtime = "bash"
  entrypoint = "handler.sh"
  memory = "128"
  execution_timeout = "10"
  
  cron_expression = "*/5 * ? * * *"

  lockbox_secret_key = "yc-key"

  zip_filename = "handler.zip"

  func_iam_binding = "serverless.functions.invoker"
}


module "cloud_function_module_with_async_invocation_to_ymq" {
  source       = "./yc-cloud-function-module-async-invocation-to-ymq"
  default_zone = "ru-central1-b"
  YC_ACCESS_KEY = var.YC_ACCESS_KEY
  YC_SECRET_KEY = var.YC_SECRET_KEY
  retries_count = 3
  visibility_timeout_seconds = 600
  receive_wait_time_seconds = 20
  message_retention_seconds = 1209600
  maxReceiveCount = 3

  runtime = "bash"
  entrypoint = "handler.sh"
  memory = "128"
  execution_timeout = "10"

  cron_expression = "*/10 * ? * * *"
  
  func_iam_binding = "admin"
  iam_sa_binding = "admin"
}


module "cloud_function_module_with_mounted_bucket" {
  source       = "./yc-cloud-function-module-with-mounted-bucket"
  default_zone = "ru-central1-b"

  runtime = "bash"
  entrypoint = "handler.sh"
  memory = "128"
  execution_timeout = "10"

  cron_expression = "*/5 * ? * * *"
  
  func_iam_binding = "admin"
}