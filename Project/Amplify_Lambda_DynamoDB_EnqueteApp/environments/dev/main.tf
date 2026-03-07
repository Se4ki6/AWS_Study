# ① DynamoDBの作成
module "dynamodb" {
  source      = "../../modules/dynamodb"
  table_name  = "vote-table-dev"
  environment = "dev"
}

# ② Lambdaの作成（DynamoDBの情報を受け取る）
module "lambda" {
  source        = "../../modules/lambda"
  function_name = "vote-api"
  environment   = "dev"

  # module.モジュール名.出力名 で渡す
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn
}

# ③ API Gatewayの作成（Lambdaの情報を受け取る）
module "api_gateway" {
  source      = "../../modules/api_gateway"
  api_name    = "vote-apigw"
  environment = "dev"

  # module.モジュール名.出力名 で渡す
  lambda_function_arn  = module.lambda.function_arn
  lambda_function_name = module.lambda.function_name
}
