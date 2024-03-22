module "cloud_function" {
  source = "../../"

  # Cloud Function Definition
  zip_filename      = "../../handler.zip"
  user_hash         = "yc-defined-string-for-tf-module" # User-defined string for current function version. User must change this string any times when function changed. Function will be updated when hash is changed.
  runtime           = "bash-2204"
  entrypoint        = "handler.sh"
  memory            = 128
  execution_timeout = 10

  # Cloud Function Scaling Policy Definition
  policy = {
    tag                  = "$latest"
    zone_instances_limit = 3
    zone_requests_limit  = 100
  }
}
