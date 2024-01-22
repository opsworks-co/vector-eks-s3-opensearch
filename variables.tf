variable "name" {
  type        = string
  default     = "vector"
  description = "Name or prefix for resources that will be created."
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster where Vector going to be installed."
}

variable "secret_name" {
  type        = string
  default     = null
  description = "Secret which contains `vector_username` and `vector_password` we are using to perform Basic Authenification in OpenSearch (ElasticSearch)."
}

variable "elasticsearch_endpoint" {
  type        = string
  description = "Endpoint of OpenSearch (ElasticSearch) to which we are sending logs in format `https://elasticsearch.example.com:443`."
}

variable "aggregator_template_filename" {
  type        = string
  default     = "aggregator.yaml"
  description = "Filename with custom aggregator configuration."
}

variable "aggregator_template_variables" {
  type        = map(string)
  default     = {}
  description = "By default aggregator template has following variables: `queue_url`, `endpoint`, `region`, and `eks_cluster_name`. Module replaces them inside automatically. If you defined additional variables in the template provided via `aggregator_template_filename` you need to provide values for them here."
}

variable "agent_template_filename" {
  type        = string
  default     = null
  description = "Filename with custom agent configuration."
}

variable "agent_template_variables" {
  type        = map(string)
  default     = {}
  description = "By default agent template has following variables: `region`, `bucket`, and `cluster_name`. Module replaces them inside automatically. If you defined additional variables in the template provided via `agent_template_filename` you need to provide values for them here."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "A mapping of tags to assign to the resources."
}

variable "s3_expiration_days" {
  type        = number
  default     = 7
  description = "How many days keep log files in S3 bucket."
}

variable "helm_chart_config" {
  description = "Helm chart config. Applies to both agent and aggregator. See https://registry.terraform.io/providers/hashicorp/helm/latest/docs"
  type        = any
  default     = {}
}

variable "agent_values_override" {
  description = "Overrides or extend the Agent Helm default values and/or thouse provided in the custom template `agent_template_filename`."
  type        = any
  default     = {}
}

variable "aggregator_values_override" {
  description = "Overrides or extend the Aggregator Helm values provided in the custom template `aggregator_template_filename`."
  type        = any
  default     = {}
}

variable "s3_force_destroy" {
  type        = bool
  default     = false
  description = "A boolean that indicates all objects should be deleted from the bucket first to destroy the bucket without error."
}

variable "s3_bucket_policy" {
  type        = string
  default     = null
  description = "By default we are creating the least priviledgies S3 bucket policy (limited access only for `Agent IAM Role` and `Aggregator IAM Role`). You can override it by providing S3 bucket policy JSON document here."
}

variable "s3_bucket_name" {
  type        = string
  default     = null
  description = "By default S3 bucket name generates as `$var.name-$var.eks_cluster_name-logs`. You can override it here by providing custom name."
}
