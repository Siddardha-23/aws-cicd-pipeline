#!/bin/bash
set -e
# Creates S3 bucket and DynamoDB table for Terraform remote state
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="opsboard-terraform-state-${ACCOUNT_ID}"
TABLE_NAME="opsboard-terraform-locks"
REGION="us-east-1"

echo "Creating S3 bucket: ${BUCKET_NAME}"
aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${REGION}"
aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms"}}]}'
aws s3api put-public-access-block --bucket "${BUCKET_NAME}" --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "Creating DynamoDB table: ${TABLE_NAME}"
aws dynamodb create-table \
  --table-name "${TABLE_NAME}" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "${REGION}"

echo "Remote state infrastructure created successfully!"
echo "Update terraform/backend.tf with bucket name: ${BUCKET_NAME}"
