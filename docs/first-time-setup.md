# First-Time Setup Guide

claude --resume "aws-cicd-ecs-pipeline"

Step-by-step instructions to deploy OpsBoard from scratch on AWS.

---

## Prerequisites

Before starting, ensure you have the following installed and configured:

| Tool | Version | Purpose |
|------|---------|---------|
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) | v2+ | AWS API access |
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | v1.5+ | Infrastructure provisioning |
| [Docker](https://docs.docker.com/get-docker/) | v20+ | Building container images |
| [Git](https://git-scm.com/) | v2+ | Source control |

**AWS account requirements:**
- An AWS account with admin access (or sufficient IAM permissions to create VPCs, ECS, RDS, CodePipeline, etc.)
- AWS CLI configured with credentials: `aws configure`
- A registered domain with a Route 53 hosted zone (the root domain, e.g., `manneharshithsiddardha.com`)

**GitHub requirements:**
- A GitHub account
- The repository pushed to GitHub (the CodeStar connection will link to it)

---

## Step 1: Clone the Repository

```bash
git clone https://github.com/<your-username>/devops-cicd-ecs-pipeline.git
cd devops-cicd-ecs-pipeline
```

---

## Step 2: Bootstrap Remote Terraform State

Terraform state must be stored remotely in S3 with DynamoDB locking. A bootstrap script creates these resources.

```bash
# Create S3 bucket and DynamoDB table for Terraform state
chmod +x scripts/setup-remote-state.sh
./scripts/setup-remote-state.sh
```

This script creates:
- An S3 bucket: `opsboard-terraform-state-<account-id>`
- A DynamoDB table: `opsboard-terraform-locks`

After running the script, uncomment the backend configuration in `terraform/backend.tf` and replace the placeholder with your AWS account ID:

```hcl
terraform {
  backend "s3" {
    bucket         = "opsboard-terraform-state-<your-account-id>"
    key            = "opsboard/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "opsboard-terraform-locks"
    encrypt        = true
  }
}
```

---

## Step 3: Configure Variables

Copy the example variables file and fill in your values:

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

```hcl
project_name       = "opsboard"
environment        = "production"
aws_region         = "us-east-1"
domain_name        = "cicd.yourdomain.com"      # Your subdomain
root_domain        = "yourdomain.com"            # Must have a Route 53 hosted zone
db_name            = "opsboard"
db_username        = "opsboard_admin"
vpc_cidr           = "10.0.0.0/16"
container_insights = false                        # Set to true if you want ECS insights (adds cost)
```

---

## Step 4: Provision Infrastructure

```bash
cd terraform

# Initialize Terraform (downloads providers, initializes backend)
terraform init

# Preview what will be created
terraform plan

# Apply (type 'yes' when prompted)
terraform apply
```

This takes approximately 10-15 minutes. Terraform creates:
- VPC with 6 subnets (2 public, 2 private, 2 isolated)
- NAT instance, Internet Gateway, route tables
- Security groups for ALB, frontend, backend, and RDS
- ECR repositories for frontend and backend images
- RDS PostgreSQL instance
- SSM parameters for database credentials
- ACM certificate (with DNS validation via Route 53)
- ALB with HTTPS listener and 4 target groups (blue/green for each service)
- ECS cluster, task definitions, and services
- CodePipeline, CodeBuild project, and CodeDeploy applications
- Route 53 A record pointing to the ALB

**Save the outputs.** You will need the ECR repository URLs:

```bash
terraform output ecr_repo_urls
```

---

## Step 5: Complete the CodeStar GitHub Connection

Terraform creates the CodeStar connection in a `PENDING` state. You must manually authorize it in the AWS Console.

1. Open the [AWS CodePipeline Console](https://console.aws.amazon.com/codesuite/settings/connections).
2. Find the connection named `opsboard-production-github`.
3. Click **Update pending connection**.
4. Follow the OAuth flow to authorize AWS access to your GitHub account.
5. Select the repository and click **Connect**.

The connection status should change from `PENDING` to `AVAILABLE`.

---

## Step 6: Push Initial Docker Images to ECR

ECS services will fail to start until valid images exist in ECR. Push the initial images manually:

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="us-east-1"

# Authenticate Docker to ECR
aws ecr get-login-password --region $REGION | \
  docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and push frontend
docker build -t opsboard-frontend ./frontend
docker tag opsboard-frontend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/opsboard-production-frontend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/opsboard-production-frontend:latest

# Build and push backend
docker build -t opsboard-backend ./backend
docker tag opsboard-backend:latest $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/opsboard-production-backend:latest
docker push $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/opsboard-production-backend:latest
```

Alternatively, if a push-images script is provided:

```bash
chmod +x scripts/initial-push-images.sh
./scripts/initial-push-images.sh
```

---

## Step 7: Verify ECS Services Are Running

After pushing images, ECS services should start pulling them and launching tasks.

```bash
# Check service status
aws ecs describe-services \
  --cluster opsboard-production-cluster \
  --services opsboard-production-frontend opsboard-production-backend \
  --query 'services[*].{name:serviceName,status:status,running:runningCount,desired:desiredCount}' \
  --output table
```

Wait until `runningCount` matches `desiredCount` for both services.

If tasks are failing, check the stopped task reasons:

```bash
aws ecs list-tasks --cluster opsboard-production-cluster --desired-status STOPPED --query 'taskArns[0]' --output text | \
  xargs -I {} aws ecs describe-tasks --cluster opsboard-production-cluster --tasks {} --query 'tasks[0].stoppedReason' --output text
```

---

## Step 8: Verify the Application

Open your browser and navigate to:

```
https://cicd.manneharshithsiddardha.com
```

(Replace with your configured domain.)

Verify:
- The frontend dashboard loads
- The API responds at `https://cicd.manneharshithsiddardha.com/api/v1/health`
- The database connection is working (the health endpoint reports database status)

---

## Step 9: Trigger the Pipeline

Now that everything is running, trigger the CI/CD pipeline with a code change:

```bash
# Make a small change
echo "# pipeline test" >> README.md

# Commit and push
git add README.md
git commit -m "test: trigger CI/CD pipeline"
git push origin main
```

Monitor the pipeline in the AWS Console:
1. Open [CodePipeline Console](https://console.aws.amazon.com/codesuite/codepipeline/pipelines)
2. Click on the `opsboard-production-pipeline`
3. Watch the Source, Build, and Deploy stages complete

The blue/green deployment will:
1. Launch new tasks on the green target groups
2. Run health checks
3. Shift traffic from blue to green
4. Terminate old tasks

---

## Troubleshooting

### ECS tasks keep stopping

**Check task logs:**
```bash
aws logs tail /ecs/opsboard-production-backend --since 30m
aws logs tail /ecs/opsboard-production-frontend --since 30m
```

**Common causes:**
- Database connection refused: verify RDS is running and security groups allow traffic from backend SG to RDS SG on port 5432.
- Image not found: verify ECR has images with the expected tags.
- Health check failing: ensure the container responds on the expected port within the health check grace period.

### ACM certificate stuck in PENDING_VALIDATION

Terraform creates DNS validation records in Route 53 automatically. If the certificate is still pending after 10 minutes:
1. Check Route 53 for the CNAME validation record.
2. Ensure the hosted zone for your root domain is active and the NS records are correctly delegated.

### CodePipeline fails at Source stage

- Verify the CodeStar connection is in `AVAILABLE` state.
- Ensure the GitHub repository name in `terraform/main.tf` matches your actual repository name.
- Confirm the branch name is `main`.

### CodeBuild fails

```bash
# View build logs
aws codebuild list-builds-for-project --project-name opsboard-production-build --max-items 1 --query 'ids[0]' --output text | \
  xargs -I {} aws codebuild batch-get-builds --ids {} --query 'builds[0].logs.deepLink' --output text
```

Open the deep link to view full build logs in CloudWatch.

### NAT instance not forwarding traffic

If ECS tasks in private subnets cannot reach the internet:
1. Verify the NAT instance is running: `aws ec2 describe-instances --filters "Name=tag:Name,Values=opsboard-production-nat-instance" --query 'Reservations[0].Instances[0].State.Name'`
2. Check that `source_dest_check` is disabled on the NAT instance.
3. Verify the private route table has a `0.0.0.0/0` route pointing to the NAT instance's ENI.

### Destroying the infrastructure

To tear down all resources:

```bash
cd terraform
terraform destroy
```

Then manually delete the S3 state bucket and DynamoDB table if you no longer need them.
