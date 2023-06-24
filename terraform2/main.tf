provider "aws" {
  region = local.region
  
  default_tags {
	  tags = {
		  Project	= local.project
	  }
  }
}


################################################################################
# EKS Module
################################################################################

module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "~> 18.0"

  cluster_name    = local.name
  cluster_version = local.cluster_version

  # ID of the VPC where the cluster and its nodes will be provisioned
  vpc_id  = local.vpc
  # A list of subnet IDs where the EKS cluster control plane (ENIs) will be provisioned.
  control_plane_subnet_ids = local.public_subnets
  # A list of subnet IDs where the nodes/node groups will be provisioned.
  subnet_ids = local.private_subnets

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  # create OpenID Connect Provider for EKS to enable IRSA
  enable_irsa = true

  # Default for all node groups
  eks_managed_node_group_defaults = {
      disk_size        = 100          # default volume size
      disk_type        = "gp3"        # gp3 ebs volume
      disk_throughput  = 150          # min throughput
      disk_iops        = 3000         # min iops for gp3
      capacity_type    = "SPOT"       # default spot instance
      eni_delete       = true         # delete eni on termination
      key_name         = local.key    # default ssh keypair for nodes
      ebs_optimized    = true         # ebs optimized instance
      ami_type         = "AL2_x86_64" # default ami type for nodes
      create_launch_template  = true
      enable_monitoring       = true
      update_default_version  = false  # set new LT ver as default

      # Subnets to use (Recommended: Private Subnets)
      subnets          = local.private_subnets

      # user data for LT
      pre_userdata = local.userdata
	  
      block_device_mappings = {
        xvda = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 100
            volume_type           = "gp3"
            iops                  = 3000
            throughput            = 150
            encrypted             = false
            delete_on_termination = true
          }
        }
      }

      update_config = {
        max_unavailable_percentage = 10 # or set `max_unavailable`
      }
  }

  eks_managed_node_groups = {
    # default node group
    default = {
      name             = "default-node"
      use_name_prefix  = true
      capacity_type    = "ON_DEMAND"  # default node group to be on-demand
      desired_capacity = 2
      max_capacity     = 8
      min_capacity     = 2

      instance_types = ["t3.medium", "t3a.medium"]
    }

    # Any other Node Group
  }

  # Cluster Security Group
  cluster_security_group_additional_rules = {
    # allow public access to call api
    ingress_cluster_api = {
          description                   = "VPC to Cluster API"
          protocol                      = "tcp"
          from_port                     = 443
          to_port                       = 443
          type                          = "ingress"
          cidr_blocks                   = ["0.0.0.0/0"]
    }
    egress_nodes_ephemeral_ports_tcp = {
      description                = "To node 1025-65535"
      protocol                   = "tcp"
      from_port                  = 1025
      to_port                    = 65535
      type                       = "egress"
      source_node_security_group = true
    }
  }

  # Node Security Group
  node_security_group_additional_rules  = {
        ingress_allow_access_from_control_plane = {
                type                          = "ingress"
                protocol                      = "tcp"
                from_port                     = 9443
                to_port                       = 9443
                source_cluster_security_group = true
                description                   = "Allow access from control plane to webhook port of AWS load balancer controller"
        }
        ingress_nginx_allow_access_from_control_plane = {
                type                          = "ingress"
                protocol                      = "tcp"
                from_port                     = 8443
                to_port                       = 8443
                source_cluster_security_group = true
                description                   = "Allow access from control plane to webhook port of ingress nginx"
        }
	ingress_self_all = {
      		description = "Node to node all ports/protocols"
      		protocol    = "-1"
      		from_port   = 0
      		to_port     = 0
      		type        = "ingress"
      		self        = true
    	}
	ingress_cluster_metricserver = {
	      description                   = "Cluster to node 4443 (Metrics Server)"
	      protocol                      = "tcp"
	      from_port                     = 4443
	      to_port                       = 4443
	      type                          = "ingress"
	      source_cluster_security_group = true 
	}
        egress_cluster_jenkins = {
              description                   = "Cluster to node 4443 (Metrics Server)"
              type                          = "egress"
              protocol                      = "-1"
              from_port                     = 0
              to_port                       = 0
              type                          = "egress"
              cidr_blocks                   = ["0.0.0.0/0"]
        }
  }

  manage_aws_auth_configmap = true
	
  # Map your required users
  aws_auth_users    = var.aws_auth_users

  tags = {
    Project    = local.project
  }
}

################################################################################
# Kubernetes provider configuration
################################################################################

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}