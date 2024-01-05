locals {
  sqs_name = lower("${var.name}-${var.eks_cluster_name}")
}

module "vector_sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.1.0"

  name                       = local.sqs_name
  visibility_timeout_seconds = 10

  create_queue_policy = true
  queue_policy_statements = {
    account = {
      sid = "AccounWrite"
      actions = [
        "sqs:SendMessage",
      ]
      principals = [
        {
          type        = "Service"
          identifiers = ["s3.amazonaws.com"]
        }
      ]

      conditions = [
        {
          test     = "ArnEquals"
          variable = "aws:SourceArn"
          values   = [module.vector_s3_bucket.s3_bucket_arn]
        }
      ]
    }
  }

  tags = var.tags
}
