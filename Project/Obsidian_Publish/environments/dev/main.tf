module "amplify" {
  source   = "../../modules/Amplify"
  app_name = var.app_name
}

module "s3" {
  source      = "../../modules/S3"
  bucket_name = var.bucket_name
}
