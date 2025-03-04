terraform {
  backend "s3" {
    bucket         = "tfremotestate-fin-project"
    key            = "state"
    region         = "eu-west-2"
    dynamodb_table = "tfremotestate-lock"
  }
}

# I think the problem here is that the s3 bucket doesn't already exist. I'll create it manually and then try again.
# I'll also need to create the dynamodb table.
# I'll create the bucket first.
# I'll create the dynamodb table next.
