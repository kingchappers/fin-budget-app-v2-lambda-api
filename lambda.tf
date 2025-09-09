######################################################################
# Create Income Lambda Function
######################################################################

resource "aws_lambda_function" "create_income" {
  filename      = "./createIncome/createIncome.zip"
  function_name = "createIncome"
  role          = aws_iam_role.create_lambda_role.arn

  source_code_hash = filebase64sha256("./createIncome/createIncome.zip")

  runtime = "provided.al2023"
  handler = "bootstrap"

  environment {
    variables = {
      INCOME_TABLE = aws_dynamodb_table.income_table.name
    }
  }
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_income.function_name
  principal     = "apigateway.amazonaws.com"

  # The following format is: arn:aws:execute-api:${region}:${account_id}:${api_id}/${stage_name}/${method}/${resource}
  source_arn = "${aws_api_gateway_rest_api.fin_budget_api.execution_arn}/*/income"
}