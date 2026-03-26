module "vpc" {
  source = "./modules/vpc"

  name_prefix = local.name_prefix
  vpc_cidr    = var.vpc_cidr
  common_tags = local.common_tags
}

module "security_groups" {
  source = "./modules/security-groups"

  name_prefix    = local.name_prefix
  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block
  common_tags    = local.common_tags
}

module "ecr" {
  source = "./modules/ecr"

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

module "rds" {
  source = "./modules/rds"

  name_prefix         = local.name_prefix
  isolated_subnet_ids = module.vpc.isolated_subnet_ids
  rds_sg_id           = module.security_groups.rds_sg_id
  db_name             = var.db_name
  db_username         = var.db_username
  common_tags         = local.common_tags
}

module "secrets" {
  source = "./modules/secrets"

  name_prefix        = local.name_prefix
  db_host            = module.rds.db_endpoint
  core_db_name       = "opsboard_core"
  deployment_db_name = "opsboard_deployments"
  db_username        = module.rds.db_username
  db_password        = module.rds.db_password
  db_port            = module.rds.db_port
  common_tags        = local.common_tags
}

module "dns" {
  source = "./modules/dns"

  domain_name = var.domain_name
  zone_id     = data.aws_route53_zone.root.zone_id
  common_tags = local.common_tags
}

module "alb" {
  source = "./modules/alb"

  name_prefix       = local.name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
  certificate_arn   = module.dns.certificate_arn
  common_tags       = local.common_tags
}

module "ecs" {
  source = "./modules/ecs"

  name_prefix                    = local.name_prefix
  vpc_id                         = module.vpc.vpc_id
  public_subnet_ids              = module.vpc.public_subnet_ids
  private_subnet_ids             = module.vpc.private_subnet_ids
  frontend_sg_id                 = module.security_groups.frontend_sg_id
  core_sg_id                     = module.security_groups.core_sg_id
  deployment_sg_id               = module.security_groups.deployment_sg_id
  frontend_repo_url              = module.ecr.frontend_repo_url
  core_repo_url                  = module.ecr.core_repo_url
  deployment_repo_url            = module.ecr.deployment_repo_url
  frontend_tg_arn                = module.alb.frontend_blue_tg_arn
  core_tg_arn                    = module.alb.core_blue_tg_arn
  deployment_tg_arn              = module.alb.deployment_blue_tg_arn
  ssm_parameter_arns             = module.secrets.all_parameter_arns
  core_ssm_parameter_names       = module.secrets.core_parameter_names
  deployment_ssm_parameter_names = module.secrets.deployment_parameter_names
  container_insights             = var.container_insights
  aws_region                     = var.aws_region
  common_tags                    = local.common_tags
}

module "cicd" {
  source = "./modules/cicd"

  name_prefix              = local.name_prefix
  github_repo              = "devops-cicd-ecs-pipeline"
  github_branch            = "main"
  frontend_ecr_repo_uri    = module.ecr.frontend_repo_url
  core_ecr_repo_uri        = module.ecr.core_repo_url
  deployment_ecr_repo_uri  = module.ecr.deployment_repo_url
  ecs_cluster_name         = module.ecs.cluster_name
  frontend_service_name    = module.ecs.frontend_service_name
  core_service_name        = module.ecs.core_service_name
  deployment_service_name  = module.ecs.deployment_service_name
  frontend_blue_tg_name    = module.alb.frontend_blue_tg_name
  frontend_green_tg_name   = module.alb.frontend_green_tg_name
  core_blue_tg_name        = module.alb.core_blue_tg_name
  core_green_tg_name       = module.alb.core_green_tg_name
  deployment_blue_tg_name  = module.alb.deployment_blue_tg_name
  deployment_green_tg_name = module.alb.deployment_green_tg_name
  https_listener_arn       = module.alb.https_listener_arn
  test_listener_arn        = module.alb.test_listener_arn
  account_id               = data.aws_caller_identity.current.account_id
  aws_region               = var.aws_region
  common_tags              = local.common_tags
}

module "monitoring" {
  source = "./modules/monitoring"

  name_prefix              = local.name_prefix
  alb_arn_suffix           = module.alb.alb_arn_suffix
  frontend_tg_arn_suffix   = module.alb.frontend_blue_tg_arn_suffix
  core_tg_arn_suffix       = module.alb.core_blue_tg_arn_suffix
  deployment_tg_arn_suffix = module.alb.deployment_blue_tg_arn_suffix
  ecs_cluster_name         = module.ecs.cluster_name
  frontend_service_name    = module.ecs.frontend_service_name
  core_service_name        = module.ecs.core_service_name
  deployment_service_name  = module.ecs.deployment_service_name
  alarm_email              = var.alarm_email
  common_tags              = local.common_tags
}

################################################################################
# Route53 A Record (Alias to ALB)
################################################################################

resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.root.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }
}
