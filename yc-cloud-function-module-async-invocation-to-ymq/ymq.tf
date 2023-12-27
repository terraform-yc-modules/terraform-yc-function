resource "yandex_message_queue" "yc_queue" {
  name                        = "yc_queue"
  visibility_timeout_seconds  = var.visibility_timeout_seconds
  receive_wait_time_seconds   = var.receive_wait_time_seconds
  message_retention_seconds   = var.message_retention_seconds
  redrive_policy              = jsonencode({
    deadLetterTargetArn = yandex_message_queue.yc_dead_letter_queue.arn
    maxReceiveCount     = var.maxReceiveCount
  })
  access_key = var.YC_ACCESS_KEY
  secret_key = var.YC_SECRET_KEY
}

resource "yandex_message_queue" "yc_dead_letter_queue" {
  name                        = "yc_dead_letter_queue"
  access_key = var.YC_ACCESS_KEY
  secret_key = var.YC_SECRET_KEY
}