terraform {
  required_version = ">= 1.10"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.138"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.12"
    }
  }
}
