locals {
  es_endpoint      = "https://aos-some-endpoint.us-east-1.es.amazonaws.com:443"
  eks_cluster_name = "test-eks"
  secret_name      = "test/vector/${local.eks_cluster_name}"
}

module "vector" {
  source = "../"

  name                         = "vector"
  eks_cluster_name             = local.eks_cluster_name
  elasticsearch_endpoint       = local.es_endpoint
  secret_name                  = local.secret_name
  aggregator_template_filename = "aggregator.yaml"

  helm_chart_config = {
    namespace = "vector-logging"
  }
  agent_values_override = {
    image = {
      repository = "docker.io/timberio/vector"
    },
    logLevel = "warning"
  }

  # `custom_field_data` is defined in the aggregator.yaml as "${custom_field_data}"
  # to replace it with appropriate value we need to pass it below
  aggregator_template_variables = {
    custom_field_data = "Some custom data"
  }
  tags = {
    "Env"       = "DEV",
    "CreatedBy" = "Terraform"
  }
}
