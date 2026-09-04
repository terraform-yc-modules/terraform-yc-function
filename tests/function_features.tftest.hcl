mock_provider "yandex" {}

mock_provider "random" {}

mock_provider "time" {}

run "accepts_default_optional_function_options" {
  command = plan

  variables {
    lockbox_secret_key    = "test-key"
    lockbox_secret_value  = "test-value"
    scaling_policy        = []
    create_trigger        = false
    choosing_trigger_type = ""
  }
}

run "plans_modern_function_options" {
  command = plan

  variables {
    lockbox_secret_key    = "test-key"
    lockbox_secret_value  = "test-value"
    scaling_policy        = []
    create_trigger        = false
    choosing_trigger_type = ""

    concurrency = 10
    tmpfs_size  = 1024
    labels = {
      team = "platform"
    }
    metadata_options = {
      aws_v1_http_endpoint = 2
      gce_http_endpoint    = 2
    }
    mounts = [
      {
        name = "cache"
        mode = "rw"
        ephemeral_disk = {
          size_gb       = 1
          block_size_kb = 4096
        }
        object_storage = null
      },
      {
        name           = "assets"
        mode           = "ro"
        ephemeral_disk = null
        object_storage = {
          bucket = "assets-bucket"
          prefix = "releases"
        }
      },
    ]
  }

  assert {
    condition     = yandex_function.yc_function.concurrency == 10
    error_message = "concurrency must be passed to yandex_function"
  }

  assert {
    condition     = yandex_function.yc_function.tmpfs_size == 1024
    error_message = "tmpfs_size must be passed to yandex_function"
  }

  assert {
    condition     = yandex_function.yc_function.labels["team"] == "platform"
    error_message = "labels must be passed to yandex_function"
  }
}
