# Remote state backend using S3 + DynamoDB for state locking.
# Prerequisites: run scripts/setup-remote-state.sh first to create
# the S3 bucket and DynamoDB table, then replace <ACCOUNT_ID> below
# with your AWS account ID.

terraform {
  backend "s3" {
    bucket         = "opsboard-terraform-state-024230653681"
    key            = "opsboard/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "opsboard-terraform-locks"
    encrypt        = true
  }
}
