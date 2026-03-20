# Cost Estimate

Monthly cost breakdown for the OpsBoard infrastructure running in AWS `us-east-1`.

All prices are based on AWS on-demand pricing as of 2025. Actual costs may vary slightly based on usage patterns and pricing changes.

---

## Monthly Cost Summary

| Resource | Specification | Monthly Cost | Notes |
|----------|--------------|-------------|-------|
| ALB | 1 ALB, ~1 LCU average | ~$18.00 | $16.20 fixed + ~$1.80 LCU charges |
| NAT Instance | t3.micro | $0.00 | Free tier eligible (first 12 months) |
| ECS Fargate | 2 tasks (0.25 vCPU, 512 MB each) | ~$15.00 | $0.04048/vCPU/hr + $0.004445/GB/hr |
| RDS PostgreSQL | db.t3.micro, 20 GB gp2 | $0.00 | Free tier eligible (first 12 months) |
| CodePipeline | 1 active pipeline | ~$1.00 | $1/active pipeline/month |
| Route 53 | 1 hosted zone | ~$0.50 | $0.50/hosted zone/month |
| ECR | ~500 MB image storage | ~$0.05 | $0.10/GB/month |
| CloudWatch Logs | ~1 GB ingestion/month | ~$0.50 | $0.50/GB ingestion + $0.03/GB storage |
| S3 | State file + pipeline artifacts | ~$0.05 | Minimal storage (<1 GB) |
| ACM | 1 TLS certificate | $0.00 | Free with ALB |
| CodeBuild | ~30 build-minutes/month | ~$0.50 | $0.005/min (general1.small, Linux) |
| Elastic IP | 1 EIP (attached to NAT) | $0.00 | Free while attached to a running instance |
| **Total (with free tier)** | | **~$36/month** | |
| **Total (after free tier)** | | **~$51/month** | NAT +$7.50, RDS +$12.50 minus EIP changes |

---

## Detailed Calculations

### Application Load Balancer -- ~$18/month

| Component | Calculation | Cost |
|-----------|-----------|------|
| Fixed hourly charge | $0.0225/hr x 720 hrs | $16.20 |
| LCU charges (estimated) | ~1 LCU avg x $0.008/LCU-hr x 720 hrs | ~$1.80 |
| **Subtotal** | | **~$18.00** |

An LCU (Load Balancer Capacity Unit) is based on four dimensions: new connections, active connections, processed bytes, and rule evaluations. For a low-traffic dashboard application, 1 LCU average is a conservative estimate.

### NAT Instance -- $0 (free tier) / $7.50 (post-free-tier)

| Component | Calculation | Cost |
|-----------|-----------|------|
| t3.micro on-demand | $0.0104/hr x 720 hrs | $7.49 |
| Free tier discount | 750 hrs/month (first 12 months) | -$7.49 |
| **Subtotal (with free tier)** | | **$0.00** |

After the 12-month free tier expires, this becomes the second-largest cost item. Consider purchasing a Reserved Instance for ~$4.50/month (1-year, no upfront).

**Cost comparison with NAT Gateway:**

| Option | Monthly Cost | Savings |
|--------|-------------|---------|
| NAT Gateway | $32.40 + data processing | -- |
| NAT Instance (t3.micro) | $0 - $7.50 | $25 - $32/month |

### ECS Fargate -- ~$15/month

| Task | vCPU | Memory | Hourly Cost | Monthly Cost |
|------|------|--------|-------------|-------------|
| Frontend | 0.25 vCPU | 512 MB | $0.01234 | $8.88 |
| Backend | 0.25 vCPU | 512 MB | $0.01234 | $8.88 |
| **Subtotal** | | | | **~$15.00** |

Calculation per task:
- vCPU: 0.25 x $0.04048/hr = $0.01012/hr
- Memory: 0.5 GB x $0.004445/hr = $0.00222/hr
- Total: $0.01234/hr x 720 hrs = $8.88/month

During blue/green deployments, both blue and green tasks run simultaneously for a few minutes. This overlap adds negligible cost (~$0.02 per deployment).

### RDS PostgreSQL -- $0 (free tier) / $12.50 (post-free-tier)

| Component | Calculation | Cost |
|-----------|-----------|------|
| db.t3.micro on-demand | $0.017/hr x 720 hrs | $12.24 |
| Storage (20 GB gp2) | $0.115/GB x 20 GB | $2.30 |
| Free tier discount | 750 hrs + 20 GB (first 12 months) | -$14.54 |
| **Subtotal (with free tier)** | | **$0.00** |

### CodePipeline -- ~$1/month

| Component | Calculation | Cost |
|-----------|-----------|------|
| 1 active pipeline | $1.00/pipeline/month | $1.00 |
| **Subtotal** | | **$1.00** |

A pipeline is billed only if it has at least one execution during the month.

### CodeBuild -- ~$0.50/month

| Component | Calculation | Cost |
|-----------|-----------|------|
| general1.small, Linux | $0.005/min x ~30 min | $0.15 |
| Free tier | 100 build-minutes/month | -$0.15 |
| **Subtotal (estimated)** | | **~$0.50** |

The first 100 build-minutes per month are free. Cost depends on push frequency. At 2 pushes per day with 5-minute builds, monthly usage would be ~300 minutes = $1.50 (minus the free 100 minutes = $1.00).

### Other Services

| Service | Calculation | Monthly Cost |
|---------|-----------|-------------|
| Route 53 hosted zone | $0.50/zone | $0.50 |
| Route 53 queries | $0.40/million queries | ~$0.01 |
| ECR storage | ~500 MB x $0.10/GB | $0.05 |
| S3 (state + artifacts) | <1 GB x $0.023/GB | $0.05 |
| CloudWatch Logs ingestion | ~1 GB x $0.50/GB | $0.50 |
| CloudWatch Logs storage | ~1 GB x $0.03/GB | $0.03 |
| Elastic IP | Free while attached | $0.00 |
| ACM certificate | Free with AWS services | $0.00 |

---

## Free Tier Expiration Impact

After the 12-month AWS free tier expires, the following costs increase:

| Resource | With Free Tier | After Free Tier | Increase |
|----------|---------------|----------------|----------|
| NAT Instance (t3.micro) | $0 | ~$7.50 | +$7.50 |
| RDS (db.t3.micro, 20 GB) | $0 | ~$14.50 | +$14.50 |
| CodeBuild (100 min free) | ~$0.50 | ~$1.50 | +$1.00 |
| **Total impact** | | | **~+$23/month** |

**Estimated total after free tier: ~$51/month**

---

## Cost Optimization Tips

### Currently Applied

1. **NAT Instance instead of NAT Gateway** -- saves ~$32/month.
2. **t3.micro instances** -- smallest practical instance sizes for NAT and RDS.
3. **S3 Gateway Endpoint** -- ECR pulls and artifact access bypass NAT, eliminating data transfer charges through the NAT instance.
4. **Container Insights disabled** -- avoids additional CloudWatch costs (~$3.60/month per task).
5. **Single-AZ NAT** -- one NAT instance instead of two (acceptable for non-HA workloads).
6. **gp2 storage for RDS** -- minimum 20 GB, no provisioned IOPS.

### Future Optimizations

1. **Fargate Spot** -- for non-production tasks, Fargate Spot offers up to 70% savings. Not recommended for production workloads without graceful interruption handling.
2. **Reserved Instances** -- purchasing a 1-year RI for the NAT instance reduces cost from $7.50 to ~$4.50/month.
3. **RDS Reserved Instance** -- 1-year RI for db.t3.micro reduces cost from ~$12.50 to ~$8/month.
4. **Scheduled scaling** -- scale ECS tasks to 0 during off-hours for dev/staging environments.
5. **ECR lifecycle policies** -- automatically delete untagged images older than 30 days to reduce storage costs.
6. **S3 Intelligent-Tiering** -- for the Terraform state bucket if it grows significantly.

### Cost Allocation Tags

All infrastructure resources are tagged with the following tags for cost tracking in AWS Cost Explorer:

| Tag Key | Value | Purpose |
|---------|-------|---------|
| `Project` | `opsboard` | Identifies all resources belonging to this project |
| `Environment` | `production` | Distinguishes environments (production/staging/dev) |
| `CostCenter` | `opsboard-cicd` | Groups costs for billing/chargeback reporting |
| `ManagedBy` | `terraform` | Identifies provisioning method |

**To enable cost tracking by these tags:**

1. Go to **AWS Billing Console** > **Cost Allocation Tags**
2. Select the `Project`, `Environment`, and `CostCenter` tags
3. Click **Activate** (tags take ~24 hours to appear in Cost Explorer)
4. In **Cost Explorer**, use "Group by → Tag: Project" to filter costs for `opsboard`

These tags are applied at two levels:
- **Provider default_tags** in `providers.tf` — automatically applied to every AWS resource
- **Module common_tags** in `locals.tf` — merged with resource-specific tags (e.g., `Name`, `Tier`)

This ensures 100% tag coverage across all 62+ AWS resources that support tagging.

### Cost Monitoring

Set up a billing alarm to receive notifications when costs exceed your expected budget:

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name "MonthlyBudgetAlarm" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions <your-sns-topic-arn> \
  --dimensions Name=Currency,Value=USD
```

---

## Cost Comparison with Alternatives

| Approach | Monthly Cost | Notes |
|----------|-------------|-------|
| **This project (OpsBoard)** | **~$36** | ECS Fargate, NAT Instance, RDS free tier |
| ECS with NAT Gateway | ~$68 | +$32 for NAT Gateway |
| EKS Fargate | ~$109 | +$73 for EKS control plane |
| EC2 instances (no containers) | ~$25 | Lower cost, higher operational burden |
| Lambda + API Gateway | ~$5 | Lowest cost, requires architecture redesign |

This architecture strikes a balance between production-grade infrastructure and cost efficiency, making it suitable for portfolio projects, demos, and small production workloads.
