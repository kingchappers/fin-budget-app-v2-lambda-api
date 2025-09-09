######################################################################
#  Create dynamodb table for income
######################################################################

resource "aws_dynamodb_table" "income_table" {
  name           = "incomeTable"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "UserId"
  range_key      = "IncomeId"

  attribute {
    name = "UserId"
    type = "S"
  }

  attribute {
    name = "IncomeId"
    type = "S"
  }

  tags = {
    Name        = "incomeTable"
    Environment = "production"
    App         = "fin-budget-app"
  }
}
