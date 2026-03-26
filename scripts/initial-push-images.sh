#!/bin/bash
set -e
# Builds and pushes initial Docker images to ECR
# Required after terraform apply creates ECR repos, before ECS services can start

REGION="us-east-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_BASE="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
PREFIX="opsboard-production"

echo "Logging into ECR..."
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ECR_BASE}

echo "Building and pushing frontend..."
docker build -t ${ECR_BASE}/${PREFIX}-frontend:latest frontend/
docker push ${ECR_BASE}/${PREFIX}-frontend:latest

echo "Building and pushing core-service..."
docker build -t ${ECR_BASE}/${PREFIX}-core:latest services/core-service/
docker push ${ECR_BASE}/${PREFIX}-core:latest

echo "Building and pushing deployment-service..."
docker build -t ${ECR_BASE}/${PREFIX}-deployment:latest services/deployment-service/
docker push ${ECR_BASE}/${PREFIX}-deployment:latest

echo "Initial images pushed successfully!"
