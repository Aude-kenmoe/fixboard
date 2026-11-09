module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  # Students run kubectl and helm from their own machine.
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = var.public_access_cidrs

  # Needed for IAM Roles for Service Accounts (IRSA).
  enable_irsa = true

  # The identity that runs terraform apply becomes cluster admin.
  enable_cluster_creator_admin_permissions = true

  # Core add-ons. Add-ons that need IAM roles live in the addons module.
  cluster_addons = {
    vpc-cni = {
      most_recent    = true
      before_compute = true
    }
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
  }

  eks_managed_node_groups = {
    default = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = var.node_instance_types

      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size
    }
  }
    # The EKS metrics-server add-on listens on port 10251. The module's node
  # security group does not open it to the control plane by default.
  node_security_group_additional_rules = {
    ingress_cluster_metrics_server = {
      description                   = "Control plane to metrics-server"
      protocol                      = "tcp"
      from_port                     = 10251
      to_port                       = 10251
      type                          = "ingress"
      source_cluster_security_group = true
    }
  }
}
