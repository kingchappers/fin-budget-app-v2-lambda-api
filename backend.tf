terraform {
  backend "s3" {
    bucket         = "tfremotestate-fin-project"
    key            = "state"
    region         = "eu-west-2"
    dynamodb_table = "tfremotestate-lock"
  }
}
