module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # Required so kubectl and Ansible can communicate with
  # the Kubernetes API from the local control machine.
  endpoint_public_access  = true
  endpoint_private_access = true

  # Give the identity creating the cluster administrator
  # access through the EKS access-entry mechanism.
  enable_cluster_creator_admin_permissions = true

  addons = {
    coredns = {}

    kube-proxy = {}

    vpc-cni = {
      before_compute = true
    }
  }

  vpc_id = module.vpc.vpc_id

  subnet_ids = module.vpc.public_subnets

  control_plane_subnet_ids = module.vpc.public_subnets

  eks_managed_node_groups = {
    application = {
      name = "${var.cluster_name}-nodes"

      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }

  tags = local.common_tags
}
