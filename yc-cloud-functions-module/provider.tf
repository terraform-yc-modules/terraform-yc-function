terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token     = var.default_token
  cloud_id  = var.default_cloud_id
  folder_id = var.default_folder_id
  zone      = var.default_zone
}