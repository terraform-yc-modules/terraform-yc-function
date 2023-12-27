output "yandex_cloud_function_id" {
  value = "${yandex_function.test_function.id}"
  description = "Yandex Cloud Function ID"
}

output "yandex_function_trigger_id" {
  value = "${yandex_function_trigger.yc_trigger.id}"
  description = "Yandex Cloud Function Trigger ID"
}