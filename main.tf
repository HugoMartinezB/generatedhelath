module "label" {
  source = "git::https://github.com/cloudposse/terraform-null-label.git"
  name   = "hugo"
  stage  = "testgh"

  tags = {
    ManagedBy = "terraform"
    GitRepo   = "git@git.catalyst-eu.net:internal/clusters"
  }
}


module "s3" {
  source = "./modules/s3"
  id     = module.label.id
}

module "bastion" {
  source            = "./modules/bastion"
  id                = module.label.id
  vpc_id            = module.aws-vpc.vpc_id
  public_subnet_ids = module.aws-vpc.public_subnets
  s3_bucket_name    = module.s3.bucket_name
  whitelisted_ips = {
    hugo = "192.168.0.1/32"
  }
}

module "users" {
  source          = "./modules/users"
  id              = module.label.id
  topic_arn       = module.s3.topic_arn
  bastion_host_id = module.bastion.bastion_host_id
  bastion_users = {
    "Hugo"   = { email = "hugo.martinez@catalyst-eu.net" }
    "Telmo"  = { email = "telmo.sampaio@generatedhealth.com" }
    "Kashif" = { email = "kashif.ahmed@generatedhealth.com" }
    "Alex"   = { email = "alex.smith@generatedhealth.com" }
  }

}