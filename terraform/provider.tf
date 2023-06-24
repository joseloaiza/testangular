//>>Uncomment this section once EKS is created - Start
#  data "aws_eks_cluster" "cluster" {
#    name = "eksclusterdemo" #module.in28minutes-cluster.cluster_name
#  }
# data "aws_eks_cluster_auth" "cluster" {
#   name = "ieksclusterdemo" #module.in28minutes-cluster.cluster_name
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

provider "aws" {
  region  = "us-east-1"
}