# OpsBoard - DevOps Operations Dashboard 

**Production-grade CI/CD pipeline: GitHub -> AWS CodePipeline -> CodeBuild -> ECS (Blue/Green via CodeDeploy)**

OpsBoard is a full-stack DevOps operations dashboard that tracks services, deployments, and incidents. The project demonstrates a production-ready CI/CD pipeline on AWS, with infrastructure fully managed by Terraform.

---

## Architecture Overview

Every push to `main` triggers a fully automated pipeline:

1. **GitHub** -- source code change detected via CodeStar connection
2. **AWS CodePipeline** -- orchestrates the entire release process
3. **AWS CodeBuild** -- builds Docker images for frontend and backend, pushes to ECR
4. **AWS CodeDeploy** -- performs blue/green deployments on ECS Fargate
5. **Application Load Balancer** -- shifts traffic from blue to green target groups
6. **ECS Fargate** -- runs the application containers with zero-downtime cutover

The application runs inside a 3-tier VPC with public, private, and isolated subnets. A NAT instance (t3.micro) replaces NAT Gateway to keep costs under $40/month.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React, TypeScript, Tailwind CSS |
| Backend | Flask, SQLAlchemy, Marshmallow |
| Database | PostgreSQL (RDS) |
| Infrastructure | Terraform (modular) |
| Containers | Docker, ECS Fargate |
| CI/CD | CodePipeline, CodeBuild, CodeDeploy |
| Networking | VPC, ALB, Route 53, ACM |
| Cost Optimization | NAT Instance (t3.micro), Fargate Spot-ready |

---

## Project Structure

```
aws-cicd-pipeline/
|-- frontend/                  # React app (Nginx-served in production)
|   |-- Dockerfile
|   |-- nginx/                 # Nginx config for SPA + reverse proxy
|   `-- src/
|-- backend/                   # Flask API
|   |-- Dockerfile
|   |-- app/
|   |   |-- api/v1/            # REST endpoints (health, dashboard, services, deployments, incidents)
|   |   |-- models/            # SQLAlchemy models
|   |   |-- schemas/           # Marshmallow serialization
|   |   |-- services/          # Business logic layer
|   |   `-- middleware/        # Error handling, security headers
|   |-- config.py
|   |-- wsgi.py
|   `-- tests/
|-- terraform/                 # Infrastructure as Code
|   |-- main.tf                # Module orchestration
|   |-- variables.tf
|   |-- outputs.tf
|   `-- modules/
|       |-- vpc/               # 3-tier VPC with NAT instance
|       |-- security-groups/   # Least-privilege security groups
|       |-- ecr/               # Container registries
|       |-- rds/               # PostgreSQL database
|       |-- secrets/           # SSM Parameter Store
|       |-- alb/               # ALB with blue/green target groups
|       |-- ecs/               # Fargate cluster, services, task definitions
|       |-- cicd/              # CodePipeline, CodeBuild, CodeDeploy
|       `-- dns/               # Route 53 + ACM certificate
|-- codedeploy/                # AppSpec and task definition templates
|   |-- appspec-frontend.yaml
|   |-- appspec-backend.yaml
|   |-- taskdef-frontend.json
|   `-- taskdef-backend.json
|-- docker-compose.yml         # Local development
`-- docs/                      # Documentation
    |-- architecture.md
    |-- first-time-setup.md
    |-- iam-roles.md
    `-- cost-estimate.md
```

---

## Quick Start (Local Development)

**Prerequisites:** Docker and Docker Compose installed.

```bash
# Clone the repository
git clone https://github.com/<your-username>/devops-cicd-ecs-pipeline.git
cd devops-cicd-ecs-pipeline

# Start all services
docker-compose up --build

# Access the application
# Frontend: http://localhost:3000
# Backend:  http://localhost:5000/api/v1/health
```

The local stack includes:
- **Frontend** on port 3000 (Nginx serving the React build)
- **Backend** on port 5000 (Flask with Gunicorn)
- **PostgreSQL** on port 5432 (data persisted in a Docker volume)

---

## Deployment

For first-time AWS deployment, see the step-by-step guide:

**[First-Time Setup Guide](docs/first-time-setup.md)**

Summary of steps:
1. Bootstrap remote Terraform state (S3 + DynamoDB)
2. Configure `terraform.tfvars`
3. Run `terraform apply` to provision all infrastructure
4. Complete the CodeStar GitHub connection in the AWS Console
5. Push initial Docker images to ECR
6. Trigger the pipeline with a code change

---

## CI/CD Pipeline

The pipeline runs automatically on every push to `main`:

| Stage | Service | Action |
|-------|---------|--------|
| **Source** | CodePipeline + CodeStar | Pulls latest code from GitHub |
| **Build** | CodeBuild | Builds Docker images, runs tests, pushes to ECR |
| **Deploy** | CodeDeploy | Blue/green deployment to ECS Fargate |

Blue/green deployment flow:
1. CodeDeploy launches new tasks on the **green** target group
2. ALB test listener routes test traffic to green for validation
3. After validation, production listener shifts 100% traffic to green
4. Original (blue) tasks are terminated after a configurable wait period

---

## Security Features

- **3-tier VPC isolation** -- public (ALB), private (ECS), isolated (RDS) subnets
- **Least-privilege IAM** -- each role has only the permissions it needs ([details](docs/iam-roles.md))
- **Security groups** -- traffic restricted between tiers; RDS only accepts connections from backend
- **SSM Parameter Store** -- database credentials stored as SecureString parameters
- **HTTPS everywhere** -- ACM certificate on ALB, HTTP redirected to HTTPS
- **Security headers** -- HSTS, X-Content-Type-Options, X-Frame-Options set by Flask middleware
- **Rate limiting** -- Flask-Limiter protects API endpoints
- **CORS** -- configured to allow only the application domain
- **No public database access** -- RDS in isolated subnets with no internet route

---

## Cost Estimate

| Resource | Monthly Cost |
|----------|-------------|
| ALB | ~$18 |
| ECS Fargate (2 tasks) | ~$15 |
| CodePipeline | ~$1 |
| CloudWatch, ECR, S3, Route 53 | ~$2 |
| NAT Instance (t3.micro) | $0 (free tier) |
| RDS (db.t3.micro) | $0 (free tier) |
| **Total** | **~$36/month** |

After free tier expiration: ~$51/month. See [full cost breakdown](docs/cost-estimate.md).

---

## Architecture Highlights

- **3-tier VPC** -- public, private, and isolated subnets across 2 AZs. Only the ALB is internet-facing; ECS tasks and RDS have no direct public access.
- **Blue/green deployments** -- zero-downtime releases with automatic rollback on health check failure. Separate blue and green target groups for both frontend and backend.
- **Least-privilege IAM** -- every role is scoped to only the AWS actions it requires. No wildcard resource permissions.
- **NAT instance for cost optimization** -- a t3.micro EC2 instance replaces NAT Gateway ($32/month savings), eligible for free tier.
- **Modular Terraform** -- nine isolated modules that can be modified, tested, or replaced independently.
- **S3 Gateway Endpoint** -- ECR image pulls and artifact storage bypass NAT, reducing data transfer costs.

---

## Documentation

| Document | Description |
|----------|-------------|
| [Architecture](docs/architecture.md) | Diagrams and component descriptions |
| [First-Time Setup](docs/first-time-setup.md) | Step-by-step deployment guide |
| [IAM Roles](docs/iam-roles.md) | Role inventory and permission rationale |
| [Cost Estimate](docs/cost-estimate.md) | Detailed monthly cost breakdown |
