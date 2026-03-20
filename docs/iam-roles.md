# IAM Roles and Permissions

This document inventories every IAM role in the OpsBoard infrastructure, lists the permissions attached to each, and explains why each permission is required.

All roles follow the **principle of least privilege**: each role is granted only the minimum permissions necessary to perform its function. No role uses wildcard (`*`) resource ARNs where a scoped ARN is feasible.

---

## Role Inventory

| Role | Trusted Service | Purpose |
|------|----------------|---------|
| ECS Task Execution Role | `ecs-tasks.amazonaws.com` | Pull images from ECR, read secrets from SSM, write logs |
| ECS Task Role | `ecs-tasks.amazonaws.com` | Application-level AWS access (minimal) |
| CodeBuild Service Role | `codebuild.amazonaws.com` | Build images, push to ECR, write logs, access artifacts |
| CodeDeploy Service Role | `codedeploy.amazonaws.com` | Manage ECS deployments and ALB target groups |
| CodePipeline Service Role | `codepipeline.amazonaws.com` | Orchestrate pipeline stages |
| NAT Instance Role | `ec2.amazonaws.com` | (Optional) CloudWatch monitoring for the NAT instance |

---

## 1. ECS Task Execution Role

**Name:** `opsboard-production-ecs-execution-role`
**Trusted entity:** `ecs-tasks.amazonaws.com`

This role is assumed by the ECS agent (not the application) to set up the container environment before the application starts.

### Permissions

| Action | Resource | Why Needed |
|--------|----------|-----------|
| `ecr:GetAuthorizationToken` | `*` | Authenticate to ECR (global action, cannot be scoped) |
| `ecr:BatchCheckLayerAvailability` | ECR repo ARNs | Check if image layers exist before pulling |
| `ecr:GetDownloadUrlForLayer` | ECR repo ARNs | Download image layers |
| `ecr:BatchGetImage` | ECR repo ARNs | Retrieve image manifests |
| `ssm:GetParameters` | SSM parameter ARNs (`/opsboard/*`) | Read database connection parameters injected as container environment variables |
| `ssm:GetParameter` | SSM parameter ARNs (`/opsboard/*`) | Read individual parameters |
| `logs:CreateLogStream` | CloudWatch log group ARN | Create log streams for task output |
| `logs:PutLogEvents` | CloudWatch log group ARN | Write container stdout/stderr to CloudWatch |
| `logs:CreateLogGroup` | CloudWatch log group ARN | Create the log group if it does not exist |

### What this role cannot do

- Cannot push images to ECR
- Cannot modify or delete SSM parameters
- Cannot access any other AWS services
- Cannot read SSM parameters outside the `/opsboard/` prefix

---

## 2. ECS Task Role

**Name:** `opsboard-production-ecs-task-role`
**Trusted entity:** `ecs-tasks.amazonaws.com`

This role is assumed by the running application container. It defines what AWS API calls the application code can make.

### Permissions

| Action | Resource | Why Needed |
|--------|----------|-----------|
| (none or minimal) | -- | The application communicates only with the database via direct TCP. No AWS SDK calls are needed at the application layer. |

If the application later needs to access AWS services (e.g., S3 for file uploads, SES for email), permissions would be added here rather than to the execution role.

### Why a separate role?

The execution role and task role serve different purposes:
- **Execution role** -- used by the ECS agent before the container starts (image pull, secret injection).
- **Task role** -- used by the application code during runtime.

Separating them ensures that application code cannot pull arbitrary ECR images or read SSM parameters outside its scope.

---

## 3. CodeBuild Service Role

**Name:** `opsboard-production-codebuild-role`
**Trusted entity:** `codebuild.amazonaws.com`

CodeBuild assumes this role during the build phase to compile code, build Docker images, push them to ECR, and generate deployment artifacts.

### Permissions

| Action | Resource | Why Needed |
|--------|----------|-----------|
| `ecr:GetAuthorizationToken` | `*` | Authenticate to ECR |
| `ecr:BatchCheckLayerAvailability` | ECR repo ARNs | Check existing layers (for caching) |
| `ecr:GetDownloadUrlForLayer` | ECR repo ARNs | Pull base images from ECR |
| `ecr:BatchGetImage` | ECR repo ARNs | Read image manifests |
| `ecr:PutImage` | ECR repo ARNs | Push built images |
| `ecr:InitiateLayerUpload` | ECR repo ARNs | Start layer upload |
| `ecr:UploadLayerPart` | ECR repo ARNs | Upload image layers |
| `ecr:CompleteLayerUpload` | ECR repo ARNs | Finalize layer upload |
| `logs:CreateLogGroup` | CodeBuild log group ARN | Create log group for build output |
| `logs:CreateLogStream` | CodeBuild log group ARN | Create log stream per build |
| `logs:PutLogEvents` | CodeBuild log group ARN | Write build logs |
| `s3:GetObject` | Pipeline artifact bucket ARN | Read source artifacts from CodePipeline |
| `s3:PutObject` | Pipeline artifact bucket ARN | Write build output artifacts for CodeDeploy |
| `s3:GetBucketAcl` | Pipeline artifact bucket ARN | Required by CodeBuild for artifact access |

### What this role cannot do

- Cannot delete ECR repositories or images
- Cannot access RDS, ECS, or any other compute services
- Cannot read SSM parameters or secrets
- Cannot access S3 buckets other than the pipeline artifact bucket

---

## 4. CodeDeploy Service Role

**Name:** `opsboard-production-codedeploy-role`
**Trusted entity:** `codedeploy.amazonaws.com`

CodeDeploy assumes this role to orchestrate blue/green deployments on ECS, managing target group registration and traffic shifting.

### Permissions

| Action | Resource | Why Needed |
|--------|----------|-----------|
| `ecs:DescribeServices` | ECS service ARNs | Read current service configuration |
| `ecs:CreateTaskSet` | ECS service ARNs | Create new task set for green deployment |
| `ecs:UpdateServicePrimaryTaskSet` | ECS service ARNs | Promote green task set to primary |
| `ecs:DeleteTaskSet` | ECS service ARNs | Remove old blue task set after cutover |
| `ecs:DescribeTaskSets` | ECS service ARNs | Monitor task set status during deployment |
| `elasticloadbalancing:DescribeTargetGroups` | `*` | Read target group configuration |
| `elasticloadbalancing:DescribeListeners` | `*` | Read listener configuration |
| `elasticloadbalancing:ModifyListener` | Listener ARNs | Switch listener rules from blue to green TG |
| `elasticloadbalancing:DescribeRules` | `*` | Read listener rules |
| `elasticloadbalancing:ModifyRule` | Listener rule ARNs | Update routing rules during traffic shift |
| `iam:PassRole` | ECS task execution role ARN | Pass the execution role to new task definitions |
| `ecs:RegisterTaskDefinition` | `*` | Register new task definition revisions |
| `ecs:DescribeTaskDefinition` | `*` | Read task definition details |

### What this role cannot do

- Cannot modify ECS cluster settings
- Cannot access ECR, S3, or RDS
- Cannot create or delete ALB/target groups (only modify listener routing)
- Cannot pass roles other than the specific ECS execution role

---

## 5. CodePipeline Service Role

**Name:** `opsboard-production-codepipeline-role`
**Trusted entity:** `codepipeline.amazonaws.com`

CodePipeline assumes this role to orchestrate the full release pipeline: pulling source code, invoking CodeBuild, and triggering CodeDeploy.

### Permissions

| Action | Resource | Why Needed |
|--------|----------|-----------|
| `codestar-connections:UseConnection` | CodeStar connection ARN | Access GitHub via the authorized connection |
| `codebuild:StartBuild` | CodeBuild project ARN | Trigger the build stage |
| `codebuild:BatchGetBuilds` | CodeBuild project ARN | Poll build status |
| `codedeploy:CreateDeployment` | CodeDeploy app ARNs | Trigger blue/green deployment |
| `codedeploy:GetDeployment` | CodeDeploy app ARNs | Monitor deployment progress |
| `codedeploy:GetDeploymentConfig` | `*` | Read deployment configuration |
| `codedeploy:RegisterApplicationRevision` | CodeDeploy app ARNs | Register new application revision |
| `codedeploy:GetApplicationRevision` | CodeDeploy app ARNs | Read revision details |
| `s3:GetObject` | Pipeline artifact bucket ARN | Read artifacts between stages |
| `s3:PutObject` | Pipeline artifact bucket ARN | Write artifacts between stages |
| `s3:GetBucketVersioning` | Pipeline artifact bucket ARN | Required for artifact bucket operations |
| `ecs:DescribeServices` | ECS service ARNs | Read service status for deploy stage |
| `ecs:DescribeTaskDefinition` | `*` | Read task definitions for deploy stage |
| `ecs:RegisterTaskDefinition` | `*` | Register updated task definitions |
| `iam:PassRole` | ECS execution role ARN | Pass role when registering task definitions |

### What this role cannot do

- Cannot directly access ECS tasks or containers
- Cannot modify infrastructure (VPC, ALB, RDS)
- Cannot push or pull ECR images
- Cannot read application secrets

---

## 6. NAT Instance Role (Optional)

**Name:** `opsboard-production-nat-instance-role`
**Trusted entity:** `ec2.amazonaws.com`

If an instance profile is attached to the NAT instance, it is used only for CloudWatch monitoring and Systems Manager access (for maintenance).

### Permissions

| Action | Resource | Why Needed |
|--------|----------|-----------|
| `cloudwatch:PutMetricData` | `*` | Publish custom metrics (CPU, network throughput) |
| `logs:CreateLogStream` | NAT log group ARN | Stream system logs |
| `logs:PutLogEvents` | NAT log group ARN | Write log data |
| `ssm:UpdateInstanceInformation` | `*` | (Optional) Allow SSM Session Manager for maintenance |

### What this role cannot do

- Cannot access any application resources (ECS, RDS, ECR, S3)
- Cannot modify network configuration
- Cannot assume other roles

---

## Security Principles Applied

### Principle of Least Privilege

Every role is scoped to only the resources it manages:
- ECR permissions reference specific repository ARNs, not `*`.
- S3 permissions reference only the pipeline artifact bucket.
- SSM permissions reference only the `/opsboard/` parameter prefix.
- `iam:PassRole` is restricted to specific target role ARNs.

### Role Separation

Five distinct roles prevent privilege escalation:
- CodeBuild can push images but cannot deploy them.
- CodeDeploy can deploy tasks but cannot build images.
- CodePipeline can orchestrate but cannot directly access resources.
- ECS execution role can pull images but the application task role cannot.

### No Wildcard Resources (Where Feasible)

Some AWS actions (e.g., `ecr:GetAuthorizationToken`, `ecs:RegisterTaskDefinition`) are global and require `Resource: "*"`. All other permissions are scoped to specific ARNs using Terraform interpolation.

### No Inline Credentials

No AWS access keys or secrets are hardcoded anywhere. All authentication uses IAM roles with temporary credentials via STS.
