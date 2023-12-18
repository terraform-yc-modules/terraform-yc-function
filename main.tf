resource "yandex_function" "test-function" {
  name               = "yc-function-example"
  description        = "this is the yc cloud function for tf-module"
  user_hash          = "yc-defined-string-for-tf-module" # User-defined string for current function version. User must change this string any times when function changed. Function will be updated when hash is changed.
  runtime            = "python312"
  entrypoint         = "main"
  memory             = "128"
  execution_timeout  = "10"
  service_account_id = var.default_service_account_id
  tags               = ["yc_tag"]
  secrets {
    id = "${yandex_lockbox_secret.secret.id}"
    version_id = "${yandex_lockbox_secret_version.version.id}"
    key = "yc-key"
    environment_variable = "YCKEY_ENV_VAR"
  }
  content {
    zip_filename = "function.zip"
  }
}