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

  name_prefix        = local.name_prefix
  isolated_subnet_ids = module.vpc.isolated_subnet_ids
  rds_sg_id          = module.security_groups.rds_sg_id
  db_name            = var.db_name
  db_username        = var.db_username
  common_tags        = local.common_tags
}

module "secrets" {
  source = "./modules/secrets"

  name_prefix = local.name_prefix
  db_host     = module.rds.db_endpoint
  db_name     = module.rds.db_name
  db_username = module.rds.db_username
  db_password = module.rds.db_password
  db_port     = module.rds.db_port
  common_tags = local.common_tags
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

  name_prefix         = local.name_prefix
  vpc_id              = module.vpc.vpc_id
  public_subnet_ids   = module.vpc.public_subnet_ids
  private_subnet_ids  = module.vpc.private_subnet_ids
  frontend_sg_id      = module.security_groups.frontend_sg_id
  backend_sg_id       = module.security_groups.backend_sg_id
  frontend_repo_url   = module.ecr.frontend_repo_url
  backend_repo_url    = module.ecr.backend_repo_url
  frontend_tg_arn     = module.alb.frontend_blue_tg_arn
  backend_tg_arn      = module.alb.backend_blue_tg_arn
  ssm_parameter_arns  = module.secrets.parameter_arns
  ssm_parameter_names = module.secrets.parameter_names
  container_insights  = var.container_insights
  aws_region          = var.aws_region
  common_tags         = local.common_tags
}

module "cicd" {
  source = "./modules/cicd"

  name_prefix            = local.name_prefix
  github_repo            = "devops-cicd-ecs-pipeline"
  github_branch          = "main"
  frontend_ecr_repo_uri  = module.ecr.frontend_repo_url
  backend_ecr_repo_uri   = module.ecr.backend_repo_url
  ecs_cluster_name       = module.ecs.cluster_name
  frontend_service_name  = module.ecs.frontend_service_name
  backend_service_name   = module.ecs.backend_service_name
  frontend_blue_tg_name  = module.alb.frontend_blue_tg_name
  frontend_green_tg_name = module.alb.frontend_green_tg_name
  backend_blue_tg_name   = module.alb.backend_blue_tg_name
  backend_green_tg_name  = module.alb.backend_green_tg_name
  https_listener_arn     = module.alb.https_listener_arn
  test_listener_arn      = module.alb.test_listener_arn
  account_id             = data.aws_caller_identity.current.account_id
  aws_region             = var.aws_region
  common_tags            = local.common_tags
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
