data "aws_eks_cluster" "eks" {
  name = var.eks_cluster_name
}

data "aws_region" "current" {}

locals {
  default_helm_chart_config = {
    chart            = "vector"
    repository       = "https://helm.vector.dev"
    version          = "0.38.1"
    namespace        = "vector"
    create_namespace = true
  }

  helm_chart_config = merge(
    local.default_helm_chart_config,
    var.helm_chart_config
  )
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      # This requires the awscli to be installed locally where Terraform is executed
      args = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.eks.name]
    }
  }
}
