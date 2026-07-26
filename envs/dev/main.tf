

module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

module "compute" {
  source = "../../modules/compute"

  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.networking.vpc_id
  public_subnets_ids    = module.networking.public_subnets_ids
  private_subnets_ids   = module.networking.private_subnets_ids
  alb_security_group_id = module.networking.alb_security_group_id
  app_security_group_id = module.networking.app_security_group_id


  depends_on = [module.networking]
}

module "observability" {
  source = "../../modules/observability"

  project_name             = var.project_name
  environment              = var.environment
  load_balancer_arn_suffix = module.compute.load_balancer_arn_suffix
  target_group_arn_suffix  = module.compute.target_group_arn_suffix
  autoscaling_group_name   = module.compute.autoscaling_group_name
  alert_email              = var.alert_email
}
