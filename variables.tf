variable "default_service_account_id" { //your service-account id
  default = "ajem568mqjomnf5o7gqh"
}

variable "default_network_id" { //your network-id
  default = "enp9rm1debn7usfmtlnv"
}

variable "default_zone" { //your default zone that is defined in provider.tf file
  default = "ru-central1-a"
}

variable "YC_VALUE" {
  type        = string
  description = "value for lockbox secret"
}