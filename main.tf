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
  function_name = "createIncome"
  role          = aws_iam_role.lambda_exec.arn

  runtime = "go1.x"
  handler = "createIncome"

  //Next items to define: 
  // 1. Zip file for where the code will be (data "archive_file") - https://docs.aws.amazon.com/lambda/latest/dg/golang-package.html
  // 2. The sha256 checksum of the zip file (source_code_hash)
  // 3. Environment variable for INCOME_TABLE used in the createIncome.go function
  // 4. Set the role for the lambda function (role)
}
