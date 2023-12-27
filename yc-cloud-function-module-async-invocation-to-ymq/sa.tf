resource "yandex_iam_service_account" "yc_sa" {
  name        = "yc-sa-for-cloud-func"
}

resource "yandex_iam_service_account_static_access_key" "yc_sa_static_key" {
  service_account_id = "${yandex_iam_service_account.yc_sa.id}"
  description        = "yc static access key for message queue"
}

resource "yandex_iam_service_account_iam_binding" "yc_admin_account_iam" {
  service_account_id = "${yandex_iam_service_account.yc_sa.id}"
  role               = var.iam_sa_binding

  members = [
    "serviceAccount:${yandex_iam_service_account.yc_sa.id}",
  ]
}