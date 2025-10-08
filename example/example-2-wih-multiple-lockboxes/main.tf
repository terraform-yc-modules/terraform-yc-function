module "cloud_function" {
  source = "../../"

  # Cloud Function Definition
  lockbox_secret_key   = var.lockbox_secret_key
  lockbox_secret_value = var.lockbox_secret_value

  zip_filename = "../../handler.zip"

  # Cloud Function Scaling Policy Definition
  scaling_policy = [{
    tag                  = "yc_tag"
    zone_instances_limit = 20
    zone_requests_limit  = 20
  }]

  # Cloud Function Trigger Definition
  choosing_trigger_type = "" # "logging"

  logging = {
    group_id     = "e23moaejmq8m74tssfu9"
    batch_cutoff = 1
    batch_size   = 1
  }

  existing_secrets = [
    {
      id                   = data.yandex_lockbox_secret.foo.secret_id
      key                  = "password"
      version_id           = data.yandex_lockbox_secret_version.foo.id
      environment_variable = "FOO_PASSWORD"
    },
    {
      id                   = data.yandex_lockbox_secret.bar.secret_id
      key                  = "password"
      version_id           = data.yandex_lockbox_secret_version.bar.id
      environment_variable = "BAR_PASSWORD"
    },
  ]
}

}
