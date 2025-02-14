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
  region  = var.region
}

resource "aws_lambda_function" "create_income" {
  function_name = "createIncome"
  role = aws_iam_role.lambda_exec.arn

  runtime = "go1.x"
  handler = "createIncome"


}
