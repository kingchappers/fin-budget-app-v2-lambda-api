terraform {
  backend "s3" {
    bucket         = "tfremotestate"
    key            = "state"
    region         = "eu-west-2"
    dynamodb_table = "tfremotestate-lock"
  }
}
