module "cloud_function_module" {
  source = "./yc-cloud-functions-module" 
  YC_VALUE = var.YC_VALUE
  default_zone = "ru-central1-b"
}