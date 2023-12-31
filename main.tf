# aws --version
# aws eks --region us-east-1 update-kubeconfig --name in28minutes-cluster
# Uses default VPC and Subnet. Create Your Own VPC and Private Subnets for Prod Usage.
# terraform-backend-state-in28minutes-123
# AKIA4AHVNOD7OOO6T4KI
#vpc-078e43cf2e3c072af
#subnet-0c4101638fbac0aac

terraform {
  backend "s3" {
    bucket = "terraform-backend-state-jlq" # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "us-east-1"
  }
}


data "aws_vpc" "selected" {
  filter {
    name = "tag:Name"
    values = ["VPC - vpc"]
  }
}


#resource "aws_default_vpc" "default" {
#
#}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  #vpc_id     = aws_default_vpc.default.id
}

data "aws_subnet" "subnet_id" {
  for_each = toset(data.aws_subnets.subnets.ids)
  id       = each.value
}


output "vpc" {
  value = data.aws_vpc.selected.id
}

output "subnet" {
  value = [for subnet in data.aws_subnet.subnet_id : subnet.id]
}



provider "kubernetes" {
  //>>Uncomment this section once EKS is created - Start
   #host                   = data.aws_eks_cluster.cluster.endpoint #module.in28minutes-cluster.cluster_endpoint
   #cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
   #token                  = data.aws_eks_cluster_auth.cluster.token
  //>>Uncomment this section once EKS is created - End
}

module "payroll-cluster" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "test-cluster"
  cluster_version = "1.27"
  subnet_ids         = ["subnet-083a90b145f64470e", "subnet-0b413521f153c850f"]  #[for subnet in data.aws_subnet.subnet_id : subnet.id] #aws_subnets.s #aws_subnet ["subnet-0c4101638fbac0aac"] #CHANGE # Donot choose subnet from us-east-1e
  vpc_id          = data.aws_vpc.selected.id

  //Newly added entry to allow connection to the api server
  //Without this change error in step 163 in course will not go away
  cluster_endpoint_public_access  = true

  # EKS Managed Node Group(s)
    eks_managed_node_group_defaults = {
      instance_types = ["t2.small", "t2.medium"]
    }

    eks_managed_node_groups = {
      blue = {}
      green = {
        min_size     = 1
        max_size     = 10
        desired_size = 2

        instance_types = ["t2.medium"]
      }
    }
}
#//>>Uncomment this section once EKS is created - Start
#  data "aws_eks_cluster" "cluster" {
#    name = module.payroll-cluster.cluster_name
#  }
# data "aws_eks_cluster_auth" "cluster" {
#   name = module.payroll-cluster.cluster_name
# }
# # We will use ServiceAccount to connect to K8S Cluster in CI/CD mode
# # ServiceAccount needs permissions to create deployments 
# # and services in default namespace
# resource "kubernetes_cluster_role_binding" "example" {
#   metadata {
#     name = "fabric8-rbac"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = "default"
#     namespace = "default"
#   }
# }
//>>Uncomment this section once EKS is created - End
# Needed to set the default region
provider "aws" {
  region  = "us-east-1"
}