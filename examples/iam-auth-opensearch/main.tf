locals {
  #Here is we providing endpoint, which we will connect to send data, it could be endpoint to the different VPC via VPC Endpoint
  es_endpoint = "https://aos-some-endpoint.us-east-1.es.amazonaws.com:443"
  #Here is we providing actual domain fqdn, we will use it in header so our SIGV4 and IAM auth work
  es_domain_endpoint = "vpc-xxx-abcdef.us-east-1.es.amazonaws.com"
  eks_cluster_name   = "test-eks"
}

module "vector" {
  source = "../../"

  name                         = "vector"
  eks_cluster_name             = local.eks_cluster_name
  elasticsearch_endpoint       = local.es_endpoint
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

  #We are providing here for our `opensearch` sink custom header for each request.
  #You need it only if you connecting to the OpenSearch in the diferent VPC via VPC Endpoint
  aggregator_values_override = {
    customConfig = {
      sinks = {
        opensearch = {
          request = {
            headers = {
              Host = local.es_domain_endpoint
            }
          }
        }
      }
    }
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
