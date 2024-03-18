module "cloud_function" {
  source = "../../"

  YC_ACCESS_KEY = "YCABadadaASadewxXsdqxasqxzaxswvsdcegecsw" # define access key for your service account here 
  YC_SECRET_KEY = "YCdSdaxeQQwdsdwxxZADCcwcwPPqasdadqwdxevX" # define secret key for your service account here 

  zip_filename = "../../handler.zip"
  YC_VALUE = "yc-value" # define value for lockbox secret here 

  lockbox_secret_key = "yc-key" # define lockbox secret key here  
}