module "cloud_function" {
  source = "../../"

  # Cloud Function Definition
  lockbox_secret_key   = var.lockbox_secret_key
  lockbox_secret_value = var.lockbox_secret_value

  zip_filename = "../../handler.zip"

  # storage_mounts = {
  #   mount_point_name = "yc-function"
  #   bucket           = "yandex-cloud-nnn"
  # }

  # Cloud Function Scaling Policy Definition
  scaling_policy = [{
    tag                  = "yc_tag"
    zone_instances_limit = 20
    zone_requests_limit  = 20
  }]

  # Cloud Function Trigger Definition
  choosing_trigger_type = "logging"

  logging = {
    group_id     = "e23moaejmq8m74tssfu9"
    batch_cutoff = 1
    batch_size   = 1
  }

  # timer = {}

  # object_storage = {
  #   bucket_id    = "yandex-cloud-nnn"
  #   batch_cutoff = 1
  #   batch_size   = 1
  # }

  # message_queue = {
  #   queue_id     = "yrn:yc:ymq:ru-central1:b1gfl7u3a9ahaamt3ore:anana"
  #   batch_cutoff = 1
  #   batch_size   = 1
  # }
}
