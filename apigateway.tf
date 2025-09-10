# ######################################################################
# # Create API Gateway
# ######################################################################

# resource "aws_api_gateway_rest_api" "fin_budget_api" {
#   name             = "fin-budget-api"
#   description      = "API for the fin budget app"
#   fail_on_warnings = true

#   tags = {
#     Name        = "fin-budget-api"
#     Environment = "production"
#     App         = "fin-budget-app"
#   }
# }

# resource "aws_api_gateway_resource" "income_api_resource" {
#   rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
#   parent_id   = aws_api_gateway_rest_api.fin_budget_api.root_resource_id
#   path_part   = "income"
# }

# resource "aws_api_gateway_resource" "income_api_greedy_resource" {
#   rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
#   parent_id   = aws_api_gateway_resource.income_api_resource.id
#   path_part   = "{proxy+}"
# }

# resource "aws_api_gateway_authorizer" "cognito_authorizer" {
#   name                             = "fin-budget-api-gateway-cognito-authorizer"
#   type                             = "COGNITO_USER_POOLS"
#   rest_api_id                      = aws_api_gateway_rest_api.fin_budget_api.id
#   authorizer_result_ttl_in_seconds = 300
#   identity_source                  = "method.request.header.Authorization"
#   provider_arns                    = [aws_cognito_user_pool.fin_budget_user_pool.arn]
# }

# resource "aws_api_gateway_method" "api_root" {
#   depends_on = [
#     aws_lambda_permission.api,
#     aws_api_gateway_authorizer.cognito_authorizer,
#     aws_api_gateway_rest_api.fin_budget_api
#   ]

#   rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
#   resource_id   = aws_api_gateway_rest_api.fin_budget_api.root_resource_id
#   http_method   = "ANY"
#   authorization = "COGNITO_USER_POOLS"
#   authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
# }

# resource "aws_api_gateway_integration" "api_root" {
#   rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
#   resource_id = aws_api_gateway_rest_api.fin_budget_api.root_resource_id
#   http_method = aws_api_gateway_method.api_root.http_method

#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.create_income.invoke_arn
# }

# resource "aws_api_gateway_method" "income_post_method" {
#   depends_on = [
#     aws_lambda_permission.api,
#     aws_api_gateway_authorizer.cognito_authorizer,
#     aws_api_gateway_rest_api.fin_budget_api
#   ]

#   rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
#   resource_id   = aws_api_gateway_resource.income_api_resource.id
#   http_method   = "POST"
#   authorization = "COGNITO_USER_POOLS"
#   authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id

#   request_parameters = {
#     "method.request.header.Authorization" = true
#   }
# }

# resource "aws_api_gateway_integration" "income_api_integration" {
#   depends_on  = [aws_api_gateway_method.income_post_method]
#   rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
#   resource_id = aws_api_gateway_resource.income_api_resource.id
#   http_method = aws_api_gateway_method.income_post_method.http_method

#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.create_income.invoke_arn
# }

# resource "aws_api_gateway_method" "income_options" {
#   depends_on = [
#     aws_api_gateway_rest_api.fin_budget_api,
#     aws_api_gateway_resource.income_api_resource
#   ]

#   rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
#   resource_id   = aws_api_gateway_resource.income_api_resource.id
#   http_method   = "OPTIONS"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "income_options_integration" {
#   rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
#   resource_id = aws_api_gateway_resource.income_api_resource.id
#   http_method = aws_api_gateway_method.income_options.http_method
#   type        = "MOCK"
#   request_templates = {
#     "application/json" = jsonencode(
#       {
#         statusCode = 200
#       }
#     )
#   }
# }

# resource "aws_api_gateway_method_response" "income_options_response" {
#   depends_on = [
#     aws_api_gateway_rest_api.fin_budget_api,
#     aws_api_gateway_resource.income_api_resource,
#     aws_api_gateway_method.income_options
#   ]

#   rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
#   resource_id = aws_api_gateway_resource.income_api_resource.id
#   http_method = aws_api_gateway_method.income_options.http_method
#   status_code = 200

#   response_models = {
#     "application/json" = "Empty"
#   }

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers"     = true
#     "method.response.header.Access-Control-Allow-Methods"     = true
#     "method.response.header.Access-Control-Allow-Origin"      = true
#     "method.response.header.Access-Control-Allow-Credentials" = true
#   }
# }

# resource "aws_api_gateway_integration_response" "income_options_response" {
#   depends_on = [aws_api_gateway_integration.income_options_integration]

#   rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
#   resource_id = aws_api_gateway_resource.income_api_resource.id
#   http_method = aws_api_gateway_method.income_options.http_method
#   status_code = aws_api_gateway_method_response.income_options_response.status_code

#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
#     "method.response.header.Access-Control-Allow-Methods"     = "'OPTIONS,POST'"
#     "method.response.header.Access-Control-Allow-Origin"      = "'https://main.d3m9wu6rhd9z99.amplifyapp.com'"
#     "method.response.header.Access-Control-Allow-Credentials" = "'true'"
#   }
# }

# resource "aws_api_gateway_deployment" "api" {
#   depends_on = [
#     aws_api_gateway_integration.income_api_integration,
#     aws_api_gateway_integration.api_root,
#     aws_api_gateway_method.income_post_method,
#     aws_api_gateway_method.api_root
#   ]

#   rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
#   description = "infrastructure deployment"

#   triggers = {
#     redeployment = sha1(jsonencode([
#       aws_api_gateway_rest_api.fin_budget_api.body,
#       aws_api_gateway_integration.income_api_integration.uri,
#     ]))
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_api_gateway_stage" "prod" {
#   stage_name    = "prod"
#   rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
#   deployment_id = aws_api_gateway_deployment.api.id

#   variables = {
#     "cors" = "true"
#   }
# }
