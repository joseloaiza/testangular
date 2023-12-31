terraform {
  backend "s3" {
    bucket = "terraform-backend-state-jlq" # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "us-east-1"
  }
}

provider "kubernetes" {
  //>>Uncomment this section once EKS is created - Start
   host                   = data.aws_eks_cluster.cluster.endpoint #module.in28minutes-cluster.cluster_endpoint
   cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
   token                  = data.aws_eks_cluster_auth.cluster.token
  //>>Uncomment this section once EKS is created - End
}

#-----------------------
# EKS CLuster Definition
#-----------------------

resource "aws_eks_cluster" "eksdemo" {
  name     = var.eks_cluster
  role_arn = aws_iam_role.eksdemorole.arn

  vpc_config {
    subnet_ids = ["subnet-083a90b145f64470e", "subnet-0b413521f153c850f"]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eksdemorole-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eksdemorole-AmazonEKSVPCResourceController,
  ]
}


#-------------------------
# IAM Role for EKS Cluster
#-------------------------

resource "aws_iam_role" "eksdemorole" {
  name = "eks-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eksdemorole-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eksdemorole.name
}

resource "aws_iam_role_policy_attachment" "eksdemorole-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eksdemorole.name
}

#--------------------------------------
# Enabling IAM Role for Service Account
#--------------------------------------

data "tls_certificate" "ekstls" {
  url = aws_eks_cluster.eksdemo.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eksopidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.ekstls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eksdemo.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "eksdoc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eksopidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eksopidc.arn]
      type        = "Federated"
    }
  }
}

#--------------------------------------
#  Enabling ServiceAccount to connect to K8S Cluster
#--------------------------------------

//>>Uncomment this section once EKS is created - Start
  data "aws_eks_cluster" "cluster" {
    name = var.eks_cluster # "eksclusterdemo" #module.in28minutes-cluster.cluster_name
  }
 data "aws_eks_cluster_auth" "cluster" {
   name = var.eks_cluster #"eksclusterdemo" #module.in28minutes-cluster.cluster_name
 }
 # We will use ServiceAccount to connect to K8S Cluster in CI/CD mode
 # ServiceAccount needs permissions to create deployments 
 # and services in default namespace
 resource "kubernetes_cluster_role_binding" "example" {
   metadata {
     name = "fabric8-rbac"
   }
   role_ref {
     api_group = "rbac.authorization.k8s.io"
     kind      = "ClusterRole"
     name      = "cluster-admin"
   }
   subject {
     kind      = "ServiceAccount"
     name      = "default"
     namespace = "default"
   }
 }
//>>Uncomment this section once EKS is created - End