data "yandex_lockbox_secret" "foo" {
  name = "foo"
}

data "yandex_lockbox_secret_version" "foo" {
  secret_id = data.yandex_lockbox_secret.foo.secret_id
}

data "yandex_lockbox_secret" "bar" {
  name = "bar"
}

data "yandex_lockbox_secret_version" "bar" {
  secret_id = data.yandex_lockbox_secret.bar.secret_id
}
