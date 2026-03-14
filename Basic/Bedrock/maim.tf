module "Provider" {
  source      = "./modules/Provider"
  aws_profile = var.aws_profile
}

module "S3" {
  source = "./modules/S3"
}

module "IAM" {
  source        = "./modules/IAM"
  random_id_hex = module.S3.random_id_hex
}

module "OpenSearch_Serverless" {
  source     = "./modules/OpenSerch_Serverless"
  role_arn   = module.IAM.role_arn
  role_id    = module.IAM.role_id
  bucket_arn = module.S3.bucket_arn
}

module "Bedrock" {
  source         = "./modules/Bedrock"
  role_arn       = module.IAM.role_arn
  collection_arn = module.OpenSearch_Serverless.collection_arn
  bucket_arn     = module.S3.bucket_arn
  depends_on     = [module.OpenSearch_Serverless]
}
