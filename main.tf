terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.88.0"
    }
  }

  required_version = "~> 1.10.5"
}

provider "aws" {
  region = var.region
}

######################################################################
# Create the policy document for the lambda function to assume the role
######################################################################

resource "aws_iam_role" "create_income_lambda_role" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

######################################################################
# Create Income Lambda Function
######################################################################

resource "aws_lambda_function" "create_income" {
  filename      = "./createIncome/createIncome.zip"
  function_name = "createIncome"
  role          = aws_iam_role.create_income_lambda_role.arn

  source_code_hash = filebase64sha256("./createIncome/createIncome.zip")

  runtime = "provided.al2023"
  handler = "bootstrap"

  environment {
    variables = {
      INCOME_TABLE = "incomeTable"
    }
  }

}

######################################################################
# Create and attach dyanmodb policy for create income lambda function
######################################################################

resource "aws_iam_policy" "create_income_dynamodb_policy" {
  name        = "create-income"
  description = "A policy to allow the lambda function to add values to the income table"
  policy      = data.aws_iam_policy_document.create_income_dynamodb.json
}

resource "aws_iam_role_policy_attachment" "attach_create_income_policy" {
  role       = aws_iam_role.create_income_lambda_role.name
  policy_arn = aws_iam_policy.create_income_dynamodb_policy.arn
}

######################################################################
# Create and attach log policy for create income lambda function
######################################################################

resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda-logging-policy"
  description = "A policy to allow the lambda function to log to CloudWatch"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.create_income_lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}


######################################################################
#  Create dynamodb table for income
######################################################################

resource "aws_dynamodb_table" "income_table" {
  name           = "incomeTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "UserId"
  range_key      = "IncomeId"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "IncomeId"
    type = "S"
  }

  tags = {
    Name        = "incomeTable"
    Environment = "production"
    App         = "fin-budget-app"
  }
}

######################################################################
# Create API Gateway
######################################################################

resource "aws_api_gateway_rest_api" "fin_budget_api" {
  name             = "fin-budget-api"
  description      = "API for the fin budget app"
  fail_on_warnings = true

  tags = {
    Name        = "fin-budget-api"
    Environment = "production"
    App         = "fin-budget-app"
  }
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_income.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.fin_budget_api.execution_arn}/*/*"
}

resource "aws_iam_role" "api_gateway_invoke_role" {
  name               = "fin-budget-api-gateway-invocation-role"
  path               = "/"
  description        = "IAM Role for API Gateway Authorizer invocations"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_invoke_role_policy_document.json
}

resource "aws_iam_policy" "api_gateway_invoke_policy" {
  name        = "fin-budget-api-gateway-invocation-policy"
  path        = "/"
  description = "IAM Policy for API Gateway Authorizer invocations"
  policy      = data.aws_iam_policy_document.api_gateway_assume_role.json

  tags = {
    Environment = "production"
    App         = "fin-budget-app"
  }
}

resource "aws_iam_role_policy_attachment" "api_gateway_invoke" {
  role       = aws_iam_role.api_gateway_invoke_role.name
  policy_arn = aws_iam_policy.api_gateway_invoke_policy.arn
}

resource "aws_api_gateway_resource" "income_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  parent_id   = aws_api_gateway_rest_api.fin_budget_api.root_resource_id
  path_part   = "income"
}

resource "aws_api_gateway_resource" "income_api_greedy_resource" {
  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  parent_id   = aws_api_gateway_resource.income_api_resource.id
  path_part   = "{proxy+}"
}

# CREATING A JWT AUTHORIZER FUNCTION FOR API GATEWAY ACCESS
# RESEARCHING HOW BEST TO DO THIS WITH COGNITO AND A TOKEN BASED AUTHORISER

# DONT USE A JWT AUTHORISER - USE A COGNITO USER POOL AUTHORISER INSTEAD
# https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-integrate-with-cognito.html

resource "aws_cognito_user_pool" "fin_budget_user_pool" {
  name                     = "fin-budget-user-pool"
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
  mfa_configuration        = "ON"

  account_recovery_setting {
    recovery_mechanism {
      priority = 1
      name     = "verified_email"
    }
    recovery_mechanism {
      priority = 2
      name     = "verified_phone_number"
    }
  }

  software_token_mfa_configuration {
    enabled = true
  }

  password_policy {
    minimum_length                   = 8
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    temporary_password_validity_days = 7
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  user_pool_tier = "LITE"

  tags = {
    Name        = "fin-budget-api"
    Environment = "production"
    App         = "fin-budget-app"
  }
}

resource "aws_cognito_user_pool_client" "fin_budget_user_pool_client" {
  name                                 = "fin-budget-user-pool-client"
  user_pool_id                         = aws_cognito_user_pool.fin_budget_user_pool.id
  callback_urls                        = ["https://localhost:8080", "https://main.d3m9wu6rhd9z99.amplifyapp.com/"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "phone"]
  supported_identity_providers         = ["COGNITO"]

  generate_secret     = false
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH"]

}

resource "aws_cognito_identity_pool" "fin_budget_cognito_identity_pool" {
  depends_on                       = [aws_cognito_user_pool.fin_budget_user_pool, aws_cognito_user_pool_client.fin_budget_user_pool_client]
  identity_pool_name               = "fin_budget_cognito_identity_pool"
  allow_unauthenticated_identities = false
  allow_classic_flow               = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.fin_budget_user_pool_client.id
    provider_name           = aws_cognito_user_pool.fin_budget_user_pool.endpoint
    server_side_token_check = false
  }
}

resource "aws_iam_role" "fin_budget_cognito_authenticated_role" {
  name               = "fin-budget-cognito-authenticated-role"
  description        = "IAM Role for authenticated users of the fin budget app"
  assume_role_policy = data.aws_iam_policy_document.fin_budget_cognito_authenticated_role_policy_document.json
}

resource "aws_iam_policy" "fin_budget_authenticated_user_permissions_policy_document" {
  name        = "fin-budget-authenticated-user-permissions-policy"
  description = "IAM Policy for authenticated users of the fin budget app"
  policy      = data.aws_iam_policy_document.fin_budget_authenticated_user_permissions_policy_document.json

  tags = {
    Environment = "production"
    App         = "fin-budget-app"
  }
}

resource "aws_iam_role_policy_attachment" "fin_budget_authenticated_user_permissions" {
  role       = aws_iam_role.fin_budget_cognito_authenticated_role.name
  policy_arn = aws_iam_policy.fin_budget_authenticated_user_permissions_policy_document.arn
}

resource "aws_iam_role" "fin_budget_cognito_unauthenticated_role" {
  name               = "fin-budget-cognito-unauthenticated-role"
  assume_role_policy = data.aws_iam_policy_document.fin_budget_cognito_unauthenticated_role_policy_document.json
}

# How do I set the role identity pool users assume when they sign in using terraform?
resource "aws_cognito_identity_pool_roles_attachment" "fin_budget_cognito_role_attachment" {
  identity_pool_id = aws_cognito_identity_pool.fin_budget_cognito_identity_pool.id

  roles = {
    authenticated   = aws_iam_role.fin_budget_cognito_authenticated_role.arn
    unauthenticated = aws_iam_role.fin_budget_cognito_unauthenticated_role.arn
  }
}

resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                             = "fin-budget-api-gateway-cognito-authorizer"
  type                             = "COGNITO_USER_POOLS"
  rest_api_id                      = aws_api_gateway_rest_api.fin_budget_api.id
  authorizer_result_ttl_in_seconds = 300
  authorizer_credentials           = aws_iam_role.api_gateway_invoke_role.arn
  identity_source                  = "method.request.header.Authorization"
  provider_arns                    = [aws_cognito_user_pool.fin_budget_user_pool.arn]
}

resource "aws_api_gateway_method" "api_root" {
  depends_on = [
    aws_lambda_permission.api,
    aws_api_gateway_authorizer.cognito_authorizer,
    aws_api_gateway_rest_api.fin_budget_api
  ]

  rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id   = aws_api_gateway_rest_api.fin_budget_api.root_resource_id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_method" "income_method" {
  depends_on = [
    aws_lambda_permission.api,
    aws_api_gateway_authorizer.cognito_authorizer,
    aws_api_gateway_rest_api.fin_budget_api
  ]

  rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id   = aws_api_gateway_resource.income_api_resource.id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

resource "aws_api_gateway_integration" "income_api_integration" {
  depends_on = [
    aws_api_gateway_rest_api.fin_budget_api,
    aws_api_gateway_resource.income_api_resource,
    aws_api_gateway_method.income_method
  ]

  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id = aws_api_gateway_resource.income_api_resource.id
  http_method = aws_api_gateway_method.income_method.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_income.invoke_arn
}

resource "aws_api_gateway_method" "income_options" {
  depends_on = [
    aws_api_gateway_rest_api.fin_budget_api,
    aws_api_gateway_resource.income_api_resource
  ]

  rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id   = aws_api_gateway_resource.income_api_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "income_options_integration" {
  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id = aws_api_gateway_resource.income_api_resource.id
  http_method = aws_api_gateway_method.income_options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_integration_response" "income_options_response" {
  depends_on = [aws_api_gateway_integration.income_options_integration]
  
  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id = aws_api_gateway_resource.income_api_resource.id
  http_method = aws_api_gateway_method.income_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,UserId'"
    "method.response.header.Access-Control-Allow-Methods"     = "'OPTIONS,POST,GET,PUT,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"      = "'*'"
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }

  response_templates = {
    "application/json" = ""
  }
}

resource "aws_api_gateway_method_response" "income_options_response" {
  depends_on = [
    aws_api_gateway_rest_api.fin_budget_api,
    aws_api_gateway_resource.income_api_resource,
    aws_api_gateway_method.income_options
  ]

  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id = aws_api_gateway_resource.income_api_resource.id
  http_method = aws_api_gateway_method.income_options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods"     = true
    "method.response.header.Access-Control-Allow-Origin"      = true
    "method.response.header.Access-Control-Max-Age"           = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_deployment" "api" {
  depends_on = [
    aws_api_gateway_method.api_root,
    aws_api_gateway_method.income_method,
    aws_api_gateway_method.income_options,
    aws_api_gateway_resource.income_api_resource,
    aws_api_gateway_integration.income_api_integration,
    aws_api_gateway_authorizer.cognito_authorizer,
  ]

  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  description = "dm-infrastructure-aws deployment"
}

resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
  deployment_id = aws_api_gateway_deployment.api.id

  variables = {
    "cors" = "true"
  }

  # Optional: enable logging, tracing, etc.
  # variables = {
  #   env = "production"
  # }
}

##########################################################################
# Create the amplify app in the deployment
# This is required so I can set the environment variables for the app
# The SSM paramaters need to be stored with the naming format
# /amplify/{your_app_id}/{your_backend_environment_name}/{your_parameter_name}
# The app_id and backend environment name are generated and need to be stored as outputs so they can be used in the storeTerraformOutputs.sh script instead of hardcoding them
# This could mean that I can remove the amplify directory from the repository
##########################################################################

# resource "aws_amplify_app" "fin-budget-app-v2" {
#   name = "fin-budget-app-v2"
#   repository = "https://github.com/kingchappers/fin-budget-app-v2"

#   # GitHub personal access token
#   # Need to provide a GitHub personal access token with repo access via a secret that Terraform can get - maybe use SSM
#   access_token = "..."

#   build_spec = <<-EOT
#     version: 1
#     backend:
#       phases:
#         build:
#           commands:
#             - npm ci --cache .npm --prefer-offline
#             - npx ampx pipeline-deploy --branch $AWS_BRANCH --app-id $AWS_APP_ID
#     frontend:
#       phases:
#         preBuild:
#           commands:
#             - export COGNITO_USER_POOL_ID=$(aws ssm get-parameter --name "/amplify/fin-budget/prod/COGNITO_USER_POOL_ID" --with-decryption --query "Parameter.Value" --output text)
#             - export COGNITO_USER_POOL_CLIENT_ID=$(aws ssm get-parameter --name "/amplify/fin-budget/prod/COGNITO_USER_POOL_CLIENT_ID" --with-decryption --query "Parameter.Value" --output text)
#             - export COGNITO_IDENTITY_POOL_ID=$(aws ssm get-parameter --name "/amplify/fin-budget/prod/COGNITO_IDENTITY_POOL_ID" --with-decryption --query "Parameter.Value" --output text)
#         build:
#           commands:
#             - npm run build
#       artifacts:
#         baseDirectory: .amplify-hosting
#         files:
#           - '**/*'
#       EOT

#   # The default rewrites and redirects added by the Amplify Console.
#   custom_rule {
#     source = "/<*>"
#     status = "404"
#     target = "/index.html"
#   }

#   environment_variables = {
#     INCOME_TABLE = aws_dynamodb_table.income_table.name
#   }

#   iam_service_role_arn = aws_iam_role.api_gateway_invoke_role.arn

#   tags = {
#     Name        = "fin-budget-app-v2"
#     Environment = "prod"
#     App         = "fin-budget-app-v2"
#   }
# }
