module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.26.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  # kubectl and Ansible connect from the local control machine.
  endpoint_public_access       = true
  endpoint_private_access      = true
  endpoint_public_access_cidrs = var.cluster_public_access_cidrs

  # Give the identity creating the cluster administrator access
  # through the EKS access-entry mechanism.
  enable_cluster_creator_admin_permissions = true

  # Keep the capstone focused and cost-aware.
  # EKS already encrypts Kubernetes secrets at rest using AWS-managed
  # encryption when no custom KMS encryption configuration is supplied.
  encryption_config = null
  create_kms_key    = false

  # Control-plane logging is not required by this capstone.
  enabled_log_types           = []
  create_cloudwatch_log_group = false

  # IRSA is not required by the application deployed in this capstone.
  enable_irsa = false

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
      # Keep resource names short enough for generated AWS IAM
      # role and launch-template name prefixes.
      name = "app-nodes"

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
