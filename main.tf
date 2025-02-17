terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_lambda_function" "create_income" {
  filename      = "./createIncome/createIncome.zip"
  function_name = "createIncome"
  role          = aws_iam_role.lambda_exec.arn

  source_code_hash = filebase64sha256("./createIncome/createIncome.zip")

  runtime = "provided.al2023"
  handler = "bootstrap"

  //Next items to define: 
  // 3. Environment variable for INCOME_TABLE used in the createIncome.go function
  // 4. Set the role for the lambda function (role)
}
