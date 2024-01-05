output "vector_s3_bucket_id" {
  description = "S3 bucket created to store logs before they parsed"
  value       = module.vector_s3_bucket.s3_bucket_id
}

