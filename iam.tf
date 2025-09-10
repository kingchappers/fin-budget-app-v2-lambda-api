
# ######################################################################
# # Create the policy document for the lambda function to assume the role
# ######################################################################

# resource "aws_iam_role" "create_lambda_role" {
#   name               = "iam_for_lambda"
#   assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
# }

# ######################################################################
# # Create and attach dyanmodb policy for create income lambda function
# ######################################################################

# resource "aws_iam_policy" "create_income_dynamodb_policy" {
#   name        = "create-income"
#   description = "IAM policy for DynamoDB access from Lambda"
#   policy      = data.aws_iam_policy_document.create_income_dynamodb.json
# }

# resource "aws_iam_role_policy_attachment" "attach_create_income_policy" {
#   role       = aws_iam_role.create_lambda_role.name
#   policy_arn = aws_iam_policy.create_income_dynamodb_policy.arn
# }

# ######################################################################
# # Create and attach log policy for create income lambda function
# ######################################################################

# resource "aws_iam_policy" "lambda_logging_policy" {
#   name        = "lambda_logging"
#   path        = "/"
#   description = "IAM policy for logging from a lambda"
#   policy      = data.aws_iam_policy_document.lambda_logging.json
# }

# resource "aws_iam_role_policy_attachment" "lambda_logs" {
#   role       = aws_iam_role.create_lambda_role.name
#   policy_arn = aws_iam_policy.lambda_logging_policy.arn
# }

# resource "aws_iam_role" "api_gateway_invoke_role" {
#   name               = "fin-budget-api-gateway-invocation-role"
#   path               = "/"
#   description        = "IAM Role for API Gateway Authorizer invocations"
#   assume_role_policy = data.aws_iam_policy_document.api_gateway_invoke_role_policy_document.json
# }

# resource "aws_iam_policy" "api_gateway_invoke_policy" {
#   name        = "fin-budget-api-gateway-invocation-policy"
#   path        = "/"
#   description = "IAM Policy for API Gateway Authorizer invocations"
#   policy      = data.aws_iam_policy_document.api_gateway_assume_role.json

#   tags = {
#     Environment = "production"
#     App         = "fin-budget-app"
#   }
# }

# resource "aws_iam_role_policy_attachment" "api_gateway_invoke" {
#   role       = aws_iam_role.api_gateway_invoke_role.name
#   policy_arn = aws_iam_policy.api_gateway_invoke_policy.arn
# }

# resource "aws_iam_role" "fin_budget_cognito_authenticated_role" {
#   name               = "fin-budget-cognito-authenticated-role"
#   description        = "IAM Role for authenticated users of the fin budget app"
#   assume_role_policy = data.aws_iam_policy_document.fin_budget_cognito_authenticated_role_policy_document.json
# }

# resource "aws_iam_policy" "fin_budget_authenticated_user_permissions_policy_document" {
#   name        = "fin-budget-authenticated-user-permissions-policy"
#   description = "IAM Policy for authenticated users of the fin budget app"
#   policy      = data.aws_iam_policy_document.fin_budget_authenticated_user_permissions_policy_document.json

#   tags = {
#     Environment = "production"
#     App         = "fin-budget-app"
#   }
# }

# resource "aws_iam_role_policy_attachment" "fin_budget_authenticated_user_permissions" {
#   role       = aws_iam_role.fin_budget_cognito_authenticated_role.name
#   policy_arn = aws_iam_policy.fin_budget_authenticated_user_permissions_policy_document.arn
# }

# resource "aws_iam_role" "fin_budget_cognito_unauthenticated_role" {
#   name               = "fin-budget-cognito-unauthenticated-role"
#   assume_role_policy = data.aws_iam_policy_document.fin_budget_cognito_unauthenticated_role_policy_document.json
# }
