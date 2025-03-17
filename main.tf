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

resource "aws_iam_role" "create_income_lambda_role" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

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

resource "aws_iam_policy" "create_income_dynamodb_policy" {
  name        = "create-income"
  description = "A policy to allow the lambda function to add values to the income table"
  policy      = data.aws_iam_policy_document.create_income_dynamodb.json
}

resource "aws_iam_role_policy_attachment" "attach_create_income_policy" {
  role       = aws_iam_role.create_income_lambda_role.name
  policy_arn = aws_iam_policy.create_income_dynamodb_policy.arn
}

resource "aws_dynamodb_table" "income_table" {
  name           = "incomeTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "userId"
  range_key      = "incomeId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "incomeId"
    type = "S"
  }

  tags = {
    Name        = "incomeTable"
    Environment = "production"
    App         = "fin-budget-app"
  }
}

