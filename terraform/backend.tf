# Uncomment this block after running the bootstrap/setup script
# that creates the S3 bucket and DynamoDB table.
#
# terraform {
#   backend "s3" {
#     bucket         = "opsboard-terraform-state-<account_id_placeholder>"
#     key            = "opsboard/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "opsboard-terraform-locks"
#     encrypt        = true
#   }
# }
