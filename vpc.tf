locals {
  cidr = "10.0.0.0/16"
  azs  = length(data.aws_availability_zones.available.names) > 3 ? slice(data.aws_availability_zones.available.names, 0, 4) : data.aws_availability_zones.available.names
}


data "aws_availability_zones" "available" {
  state = "available"
}


module "aws-vpc" {
  source           = "terraform-aws-modules/vpc/aws"
  name             = "${module.label.id} VPC"
  cidr             = local.cidr
  azs              = local.azs
  private_subnets  = [cidrsubnet(local.cidr, 4, 1), cidrsubnet(local.cidr, 4, 5), cidrsubnet(local.cidr, 4, 9)]
  database_subnets = [cidrsubnet(local.cidr, 3, 1), cidrsubnet(local.cidr, 3, 3), cidrsubnet(local.cidr, 3, 5)]
  public_subnets   = [cidrsubnet(local.cidr, 4, 0), cidrsubnet(local.cidr, 4, 4), cidrsubnet(local.cidr, 4, 8)]

  // Natgateway configs.
  create_igw           = true
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  // IPV6.
  enable_ipv6                                    = true
  public_subnet_assign_ipv6_address_on_creation  = true
  private_subnet_assign_ipv6_address_on_creation = true
  public_subnet_ipv6_prefixes                    = [0, 1, 2]
  private_subnet_ipv6_prefixes                   = [3, 4, 5, ]
  database_subnet_ipv6_prefixes                  = [6, 7, 8]

  // Defaults.
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "${module.label.id}-vpc-default" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "${module.label.id}-vpc-default" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "${module.label.id}-vpc-default" }

  // Private subnet tags
  private_subnet_names     = formatlist("${module.label.id} VPC-private-front-%s", local.azs)
  private_route_table_tags = { Name = "${module.label.id} Private Subnet Table" }

  // Public subnet tags.
  public_subnet_names     = formatlist("${module.label.id} VPC-public-%s", local.azs)
  public_route_table_tags = { Name = "${module.label.id} Public Subnet Table" }

  // Database subnet tags. 
  database_subnet_names = formatlist("${module.label.id} VPC-database-%s", local.azs)

  // IGW tags. 
  igw_tags = { Name = "${module.label.id} Internet Gateway" }

  // Tags.
  tags = module.label.tags
}