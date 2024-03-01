output "vector_s3_bucket_id" {
  description = "S3 bucket created to store logs before they parsed"
  value       = module.vector_s3_bucket.s3_bucket_id
}

output "vector_agent_role" {
  description = "IAM Role ARN created for Vector agent"
  value       = module.vector_agent_role.iam_role_arn
}

output "vector_aggregator_role" {
  description = "IAM Role ARN created for Vector aggregator"
  value       = module.vector_aggregator_role.iam_role_arn
}

output "vector_sqs_name" {
  description = "SQS created to collect events from S3 and pass to vector aggregator"
  value       = module.vector_sqs.queue_name
}
