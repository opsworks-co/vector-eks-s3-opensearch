terraform {
  required_version = ">= 1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.19.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.11.0"
    }
    utils = {
      source  = "cloudposse/utils"
      version = ">= 1.12.0"
    }
  }
}
