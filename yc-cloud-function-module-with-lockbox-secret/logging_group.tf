resource "yandex_logging_group" "yc_log_group" {
  name      = "yc-logging-group"
  description = "this is the yc logging group for tf-module"
}