resource "yandex_lockbox_secret" "secret" {
  name = "yc-secret-for-tf-module"
}

resource "yandex_lockbox_secret_version" "version" {
  secret_id = yandex_lockbox_secret.secret.id
  entries {
    key        = "yc-key"
    text_value = var.YC_VALUE
  }
}