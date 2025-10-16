locals {
  api_endpoints = {
    createIncome = {
      path = "createIncome",
      function_name = "createIncome"
      lambda_function_arn = aws_lambda_function.create_income.invoke_arn
    }, 
    getIncomes = {
      path = "getIncomes"
      function_name = "getIncomes"
      lambda_function_arn = aws_lambda_function.get_incomes.invoke_arn
    }
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

resource "aws_api_gateway_authorizer" "cognito_authorizer" {
  name                             = "fin-budget-api-gateway-cognito-authorizer"
  type                             = "COGNITO_USER_POOLS"
  rest_api_id                      = aws_api_gateway_rest_api.fin_budget_api.id
  authorizer_result_ttl_in_seconds = 300
  identity_source                  = "method.request.header.Authorization"
  provider_arns                    = [aws_cognito_user_pool.fin_budget_user_pool.arn]
}

resource "aws_api_gateway_method" "api_root" {
  depends_on = [
    aws_lambda_permission.create_income_api_permission,
    aws_api_gateway_authorizer.cognito_authorizer,
    aws_api_gateway_rest_api.fin_budget_api
  ]

  rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id   = aws_api_gateway_rest_api.fin_budget_api.root_resource_id
  http_method   = "ANY"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id
}

# resource "aws_api_gateway_integration" "api_root" {
#   rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
#   resource_id = aws_api_gateway_rest_api.fin_budget_api.root_resource_id
#   http_method = aws_api_gateway_method.api_root.http_method

#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.create_income.invoke_arn
# }

######################################################################
# Create API Gateway's Income Resources
######################################################################

resource "aws_api_gateway_resource" "api_resources" {
  for_each = local.api_endpoints
  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  parent_id   = aws_api_gateway_rest_api.fin_budget_api.root_resource_id
  path_part   = each.value.path
}

resource "aws_api_gateway_resource" "api_greedy_resource" {
  for_each = local.api_endpoints
  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  parent_id   = aws_api_gateway_resource.api_resources[each.key].id
  path_part   = "{proxy+}"
}

######################################################################
# Create API Gateway's Income OPTIONS Method
######################################################################

resource "aws_api_gateway_method" "options_method" {
  for_each = local.api_endpoints
  depends_on = [
    aws_api_gateway_rest_api.fin_budget_api,
    # aws_api_gateway_resource.api_resources[each.key].id
  ]

  rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id   = aws_api_gateway_resource.api_resources[each.key].id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  for_each = local.api_endpoints
  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id = aws_api_gateway_resource.api_resources[each.key].id
  http_method = aws_api_gateway_method.options_method[each.key].http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }
}

resource "aws_api_gateway_method_response" "options_method_response" {
  for_each = local.api_endpoints
  depends_on = [
    aws_api_gateway_rest_api.fin_budget_api,
    # aws_api_gateway_resource.api_resources[each.key],
    aws_api_gateway_method.options_method
  ]

  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id = aws_api_gateway_resource.api_resources[each.key].id
  http_method = aws_api_gateway_method.options_method[each.key].http_method
  status_code = 200

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = true
    "method.response.header.Access-Control-Allow-Methods"     = true
    "method.response.header.Access-Control-Allow-Origin"      = true
    "method.response.header.Access-Control-Allow-Credentials" = true
  }
}

resource "aws_api_gateway_integration_response" "options_response" {
  for_each = local.api_endpoints
  # depends_on = [aws_api_gateway_integration.options_response[each.key]]

  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id = aws_api_gateway_resource.api_resources[each.key].id
  http_method = aws_api_gateway_method.options_method[each.key].http_method
  status_code = aws_api_gateway_method_response.options_method_response[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers"     = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods"     = "'OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"      = "'https://finbudget.co.uk'"
    "method.response.header.Access-Control-Allow-Credentials" = "'true'"
  }
}

######################################################################
# Create API Gateway's Income POST Method
######################################################################

resource "aws_api_gateway_method" "gateway_method" {
  for_each = local.api_endpoints
  depends_on = [
    aws_lambda_permission.create_income_api_permission,
    aws_api_gateway_authorizer.cognito_authorizer,
    aws_api_gateway_rest_api.fin_budget_api
  ]

  rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id   = aws_api_gateway_resource.api_resources[each.key].id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

resource "aws_api_gateway_integration" "api_post_integration" {
  for_each = local.api_endpoints
  # depends_on  = [aws_api_gateway_method.gateway_method[each.key]]
  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  resource_id = aws_api_gateway_resource.api_resources[each.key].id
  http_method = aws_api_gateway_method.gateway_method[each.key].http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = each.value.lambda_function_arn
}

######################################################################
# Create API Gateway's Income GET Method
######################################################################

# resource "aws_api_gateway_method" "income_get_method" {
#   depends_on = [
#     aws_lambda_permission.get_income_api_permissions,
#     aws_api_gateway_authorizer.cognito_authorizer,
#     aws_api_gateway_rest_api.fin_budget_api
#   ]

#   rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
#   resource_id   = aws_api_gateway_resource.income_api_resource.id
#   # Lambda function can only be invoked via POST.
#   http_method   = "POST"
#   authorization = "COGNITO_USER_POOLS"
#   authorizer_id = aws_api_gateway_authorizer.cognito_authorizer.id

#   request_parameters = {
#     "method.request.header.Authorization" = true
#   }
# }

# resource "aws_api_gateway_integration" "income_api_get_integration" {
#   depends_on  = [aws_api_gateway_method.income_get_method]
#   rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
#   resource_id = aws_api_gateway_resource.income_api_resource.id
#   http_method = aws_api_gateway_method.income_get_method.http_method

#   # Lambda function can only be invoked via POST.
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = aws_lambda_function.get_income.invoke_arn
# }

######################################################################
# Deploy API Stage to Gateway
###################################################################### 

resource "aws_api_gateway_deployment" "api" {
  # for_each = local.api_endpoints

  depends_on = [
    # aws_api_gateway_integration.options_integration[each.key],
    # aws_api_gateway_integration.api_post_integration[each.key],
    # aws_api_gateway_integration.income_api_get_integration,
    # aws_api_gateway_integration.income_options_integration,
    # aws_api_gateway_integration.api_root,
    # aws_api_gateway_method.gateway_method[each.key],
    # aws_api_gateway_method.income_get_method,
    aws_api_gateway_method.options_method,
    # aws_api_gateway_method.api_root
  ]
  
  rest_api_id = aws_api_gateway_rest_api.fin_budget_api.id
  description = "Deployed at ${timestamp()}"


  triggers = {
    redeployment = sha1(join(",", [
      # jsonencode([
      # # REST API configuration
      # aws_api_gateway_rest_api.fin_budget_api.body,

      # # Resources
      # aws_api_gateway_resource.api_resources[each.key].id,
      # # aws_api_gateway_resource.income_api_resource.id,
      # aws_api_gateway_resource.api_greedy_resource[each.key].id,

      # # Methods
      # aws_api_gateway_method.gateway_method[each.key].id,
      # # aws_api_gateway_method.income_post_method.id,
      # # aws_api_gateway_method.income_get_method.id,
      # aws_api_gateway_method.options_method[each.key].id,

      # # Integrations
      # aws_api_gateway_integration.api_post_integration[each.key].uri,
      # # aws_api_gateway_integration.income_api_post_integration.uri,
      # # aws_api_gateway_integration.income_api_get_integration.uri,
      # aws_api_gateway_integration.options_integration[each.key].id,
      # # aws_api_gateway_integration.income_options_integration.id,

      # # CORS configuration
      # aws_api_gateway_method_response.options_method_response[each.key].response_parameters,
      # # aws_api_gateway_integration_response.income_options_response.response_parameters,
      # ]),
      timestamp() # Add this to force deployment on every apply
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.fin_budget_api.id
  deployment_id = aws_api_gateway_deployment.api.id

  variables = {
    "cors"    = "true"
    "version" = aws_api_gateway_deployment.api.id
  }

  lifecycle {
    ignore_changes = [
      deployment_id
    ]
  }
}
