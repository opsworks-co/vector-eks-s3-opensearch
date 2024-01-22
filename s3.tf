locals {
  bucket_name = coalesce(var.s3_bucket_name, lower("${var.name}-${var.eks_cluster_name}-logs"))
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid = "AccessForVectorAgentRole"
    principals {
      type        = "AWS"
      identifiers = [module.vector_agent_role.iam_role_arn]
    }
    actions   = ["s3:ListBucket", "s3:PutObject"]
    resources = ["arn:aws:s3:::${local.bucket_name}", "arn:aws:s3:::${local.bucket_name}/*"]
  }
  statement {
    sid = "AccessForVectorAggregatorRole"
    principals {
      type        = "AWS"
      identifiers = [module.vector_aggregator_role.iam_role_arn]
    }
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]
  }
}

module "vector_s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.0.1"

  bucket        = local.bucket_name
  acl           = null
  force_destroy = var.s3_force_destroy

  versioning = {
    enabled = false
  }

  lifecycle_rule = [
    {
      id      = "expiration"
      enabled = true
      expiration = {
        days = var.s3_expiration_days
      }
      abort_incomplete_multipart_upload_days = "1"
    },
    {
      id      = "remove_delete_markers"
      enabled = true
      expiration = {
        expired_object_delete_marker = true
      }
    }
  ]

  policy        = coalesce(var.s3_bucket_policy, data.aws_iam_policy_document.s3_bucket_policy.json)
  attach_policy = true

  attach_deny_insecure_transport_policy = true
  block_public_acls                     = true
  block_public_policy                   = true
  ignore_public_acls                    = true
  restrict_public_buckets               = true

  tags = var.tags
}

resource "aws_s3_bucket_notification" "object_created" {
  bucket = module.vector_s3_bucket.s3_bucket_id

  queue {
    queue_arn = module.vector_sqs.queue_arn
    events    = ["s3:ObjectCreated:*"]
  }
}
