# resource "aws_cognito_user_pool" "fin_budget_user_pool" {
#   name                     = "fin-budget-user-pool"
#   auto_verified_attributes = ["email"]
#   username_attributes      = ["email"]
#   mfa_configuration        = "ON"

#   account_recovery_setting {
#     recovery_mechanism {
#       priority = 1
#       name     = "verified_email"
#     }
#     recovery_mechanism {
#       priority = 2
#       name     = "verified_phone_number"
#     }
#   }

#   software_token_mfa_configuration {
#     enabled = true
#   }

#   password_policy {
#     minimum_length                   = 8
#     require_uppercase                = true
#     require_lowercase                = true
#     require_numbers                  = true
#     require_symbols                  = true
#     temporary_password_validity_days = 7
#   }

#   email_configuration {
#     email_sending_account = "COGNITO_DEFAULT"
#   }

#   user_pool_tier = "LITE"

#   tags = {
#     Name        = "fin-budget-api"
#     Environment = "production"
#     App         = "fin-budget-app"
#   }
# }

# resource "aws_cognito_user_pool_client" "fin_budget_user_pool_client" {
#   name                                 = "fin-budget-user-pool-client"
#   user_pool_id                         = aws_cognito_user_pool.fin_budget_user_pool.id
#   callback_urls                        = ["https://localhost:8080", "https://main.d3m9wu6rhd9z99.amplifyapp.com"]
#   allowed_oauth_flows_user_pool_client = true
#   allowed_oauth_flows                  = ["code"]
#   allowed_oauth_scopes                 = ["email", "openid", "phone"]
#   supported_identity_providers         = ["COGNITO"]

#   generate_secret = false
#   explicit_auth_flows = [
#     "ADMIN_NO_SRP_AUTH",
#     "USER_PASSWORD_AUTH"
#   ]
# }

# resource "aws_cognito_identity_pool" "fin_budget_cognito_identity_pool" {
#   depends_on                       = [aws_cognito_user_pool.fin_budget_user_pool, aws_cognito_user_pool_client.fin_budget_user_pool_client]
#   identity_pool_name               = "fin_budget_cognito_identity_pool"
#   allow_unauthenticated_identities = false
#   allow_classic_flow               = false

#   cognito_identity_providers {
#     client_id               = aws_cognito_user_pool_client.fin_budget_user_pool_client.id
#     provider_name           = aws_cognito_user_pool.fin_budget_user_pool.endpoint
#     server_side_token_check = false
#   }
# }

# resource "aws_cognito_identity_pool_roles_attachment" "fin_budget_cognito_role_attachment" {
#   identity_pool_id = aws_cognito_identity_pool.fin_budget_cognito_identity_pool.id

#   roles = {
#     authenticated   = aws_iam_role.fin_budget_cognito_authenticated_role.arn
#     unauthenticated = aws_iam_role.fin_budget_cognito_unauthenticated_role.arn
#   }
# }
