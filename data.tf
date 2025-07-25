data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup",
    ]

    resources = [
      "arn:aws:logs:eu-west-2:192350001975:*"
    ]
  }
}

data "aws_iam_policy_document" "create_income_dynamodb" {
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:PutItem"]
    resources = ["arn:aws:dynamodb:eu-west-2:192350001975:table/incomeTable"]
  }
}

data "aws_iam_policy_document" "api_gateway_assume_role" {
  statement {
    effect    = "Allow"
    actions   = ["execute-api:Invoke"]
    resources = [aws_api_gateway_rest_api.fin_budget_api.execution_arn]
    //"arn:aws:execute-api:eu-west-2:192350001975:8v1x5j0g3f/*/GET/income", 
  }

  statement {
    effect    = "Allow"
    actions   = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.create_income.arn
    ]
  }
}

data "aws_iam_policy_document" "api_gateway_invoke_role_policy_document" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "fin_budget_cognito_authenticated_role_policy_document" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.fin_budget_cognito_identity_pool.id]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["authenticated"]
    }
  }

statement {
      effect = "Allow"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query"
      ]
      resources = [
        aws_dynamodb_table.income_table.arn
      ]
    }

}

data "aws_iam_policy_document" "fin_budget_cognito_unauthenticated_role_policy_document" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "cognito-identity.amazonaws.com:aud"
      values   = [aws_cognito_identity_pool.fin_budget_cognito_identity_pool.id]
    }

    condition {
      test     = "ForAnyValue:StringLike"
      variable = "cognito-identity.amazonaws.com:amr"
      values   = ["unauthenticated"]
    }
  }
}