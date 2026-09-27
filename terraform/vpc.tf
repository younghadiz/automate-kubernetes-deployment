module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs = local.availability_zones

  public_subnets = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  enable_dns_support   = true
  enable_dns_hostnames = true

  map_public_ip_on_launch = true

  # Cost-aware capstone configuration:
  # no NAT Gateway is required for this public-subnet lab architecture.
  enable_nat_gateway = false
  enable_vpn_gateway = false

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  tags = local.common_tags
}
