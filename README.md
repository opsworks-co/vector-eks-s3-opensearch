# Documentation

## Description and Architecture

This module was created to simplify configuring logging collecting and aggregation using [Vector](https://github.com/vectordotdev/vector) with intermediate cache in AWS S3 and final destination in AWS OpenSearch (former ElasticSearch).

<p align="center">
  <img src="https://raw.githubusercontent.com/opsworks-co/vector-eks-s3-opensearch/master/.github/images/diagram.svg" alt="Architectural diagram" width="100%">
</p>

In the above diagram, you can see the components and their relations.

##### Resources you need to provide (pre-requisitions)

- **OpenSearch cluster** where **Vector Aggregator** will ingest processed logs.
- **Secrets Manager Secret** with `vector_username` and `vector_password`, which will be used as Basic Auth credentials to **OpenSearch cluster**. See the [TODO](#TODO) section.
- **EKS cluster** where **Vector Agent** and **Vector Aggregator** will be deployed.

##### Resources created by the module

- Two components will be installed into the existing **EKS cluster** using the Helm chart:
  - **Vector Agent**, as DaemonSet, collects logs and metrics from the node (including application logs) and sends them to the **S3 bucket** using the ServiceAccount and connected IAM Role. It has been done to decouple logs collecting as far as our **OpenSearch cluster** can be in the maintenance or overloaded, but we don't want to miss any logs. **S3 bucket** is cheap and reliable storage, we are using it as a buffer.
  - **Vector Aggregator**, as StatefullSet, which reads the **SQS queue** for new logs, gets them from the **S3 bucket**, processes, enriches, and sends them to the **OpenSearch cluster**.
- **S3 bucket** has lifecycle policy and stores logs for a period of time (7 days by default). It has notifications configured on CreateObject event routed to the SQS queue. Resource policy restricts access to the bucket only to **Vector Agent IAM Role** and **Vector Aggregator IAM Role**.
- **SQS queue**, as destination for S3 CreateObject notifications used by the **Vector Aggregator** to get information about logs messages that has to be processed.
- **Vector Agent IAM Role** and **Vector Aggregator IAM Role** created to provide granular access to the AWS resources.

## Explanation of some architectural decisions

- The **S3 bucket** is used as temporary storage here to not lose any logs in a case when the **OpenSearch cluster** is in the "Red health status". Messages wait in the **SQS queue** for later processing. When logs are ingested into the **OpenSearch cluster**, we remove the message from the **SQS queue**.
- When we have multiple AWS accounts (one per environment), we are using a single **OpenSearch cluster**. We believe that the **Vector Aggregator** must be part of each cluster where logs are generated so we can test changes of the **Vector Aggregator** configuration in the lower environments before promoting them to the Production.

## TODO

- Provide by default access to the **OpenSearch Cluster** using the **Vector Aggregator IAM Role** instead of the basic auth. To implement this we need to figure out how to use cross-account access to the **OpenSearch Cluster** with IAM Role via the Cluster Endpoint.
- Update module to ingest custom variables into the helm chart with [helm provider](https://registry.terraform.io/providers/hashicorp/helm/latest/docs) using [`set_sensitive`](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release#set_sensitive) to mark sensitive values, which should not be exposed to the output.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Requirements

| Name                                                                     | Version   |
| ------------------------------------------------------------------------ | --------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.3    |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | 5.19.0    |
| <a name="requirement_helm"></a> [helm](#requirement_helm)                | >= 2.11.0 |
| <a name="requirement_utils"></a> [utils](#requirement_utils)             | >= 1.12.0 |

## Providers

| Name                                                   | Version |
| ------------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws)       | 5.19.0  |
| <a name="provider_helm"></a> [helm](#provider_helm)    | 2.12.1  |
| <a name="provider_utils"></a> [utils](#provider_utils) | 1.14.0  |

## Modules

| Name                                                                                                  | Source                                                              | Version |
| ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------- | ------- |
| <a name="module_vector_agent_role"></a> [vector_agent_role](#module_vector_agent_role)                | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | v5.33.0 |
| <a name="module_vector_aggregator_role"></a> [vector_aggregator_role](#module_vector_aggregator_role) | terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc | v5.33.0 |
| <a name="module_vector_s3_bucket"></a> [vector_s3_bucket](#module_vector_s3_bucket)                   | terraform-aws-modules/s3-bucket/aws                                 | 3.15.1  |
| <a name="module_vector_sqs"></a> [vector_sqs](#module_vector_sqs)                                     | terraform-aws-modules/sqs/aws                                       | 4.1.0   |

## Resources

| Name                                                                                                                                                      | Type        |
| --------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------- |
| [aws_iam_policy.vector_agent](https://registry.terraform.io/providers/hashicorp/aws/5.19.0/docs/resources/iam_policy)                                     | resource    |
| [aws_iam_policy.vector_aggregator](https://registry.terraform.io/providers/hashicorp/aws/5.19.0/docs/resources/iam_policy)                                | resource    |
| [aws_s3_bucket_notification.object_created](https://registry.terraform.io/providers/hashicorp/aws/5.19.0/docs/resources/s3_bucket_notification)           | resource    |
| [helm_release.vector_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                         | resource    |
| [helm_release.vector_aggregator](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release)                                    | resource    |
| [aws_eks_cluster.eks](https://registry.terraform.io/providers/hashicorp/aws/5.19.0/docs/data-sources/eks_cluster)                                         | data source |
| [aws_iam_policy_document.s3_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/5.19.0/docs/data-sources/iam_policy_document)            | data source |
| [aws_iam_policy_document.vector_agent](https://registry.terraform.io/providers/hashicorp/aws/5.19.0/docs/data-sources/iam_policy_document)                | data source |
| [aws_iam_policy_document.vector_aggregator](https://registry.terraform.io/providers/hashicorp/aws/5.19.0/docs/data-sources/iam_policy_document)           | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/5.19.0/docs/data-sources/region)                                               | data source |
| [aws_secretsmanager_secret.opensearch_credentials](https://registry.terraform.io/providers/hashicorp/aws/5.19.0/docs/data-sources/secretsmanager_secret)  | data source |
| [aws_secretsmanager_secret_version.current](https://registry.terraform.io/providers/hashicorp/aws/5.19.0/docs/data-sources/secretsmanager_secret_version) | data source |
| [utils_deep_merge_yaml.values_agent_merged](https://registry.terraform.io/providers/cloudposse/utils/latest/docs/data-sources/deep_merge_yaml)            | data source |
| [utils_deep_merge_yaml.values_aggregator_merged](https://registry.terraform.io/providers/cloudposse/utils/latest/docs/data-sources/deep_merge_yaml)       | data source |

## Inputs

| Name                                                                                                                     | Description                                                                                                                                                                                                                                                                                                                 | Type          | Default             | Required |
| ------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------- | ------------------- | :------: |
| <a name="input_agent_template_filename"></a> [agent_template_filename](#input_agent_template_filename)                   | Filename with custom agent configuration.                                                                                                                                                                                                                                                                                   | `string`      | `null`              |    no    |
| <a name="input_agent_template_variables"></a> [agent_template_variables](#input_agent_template_variables)                | By default agent template has following variables: `region`, `bucket`, and `cluster_name`. Module replaces them inside automatically. If you defined additional variables in the template provided via `agent_template_filename` you need to provide values for them here.                                                  | `map(string)` | `{}`                |    no    |
| <a name="input_agent_values_override"></a> [agent_values_override](#input_agent_values_override)                         | Overrides or extend the Agent Helm default values and/or thouse provided in the custom template `agent_template_filename`.                                                                                                                                                                                                  | `any`         | `{}`                |    no    |
| <a name="input_aggregator_template_filename"></a> [aggregator_template_filename](#input_aggregator_template_filename)    | Filename with custom aggregator configuration.                                                                                                                                                                                                                                                                              | `string`      | `"aggregator.yaml"` |    no    |
| <a name="input_aggregator_template_variables"></a> [aggregator_template_variables](#input_aggregator_template_variables) | By default aggregator template has following variables: `queue_url`, `user`, `password`, `endpoint`, `region`, and `eks_cluster_name`. Module replaces them inside automatically. If you defined additional variables in the template provided via `aggregator_template_filename` you need to provide values for them here. | `map(string)` | `{}`                |    no    |
| <a name="input_aggregator_values_override"></a> [aggregator_values_override](#input_aggregator_values_override)          | Overrides or extend the Aggregator Helm values provided in the custom template `aggregator_template_filename`.                                                                                                                                                                                                              | `any`         | `{}`                |    no    |
| <a name="input_eks_cluster_name"></a> [eks_cluster_name](#input_eks_cluster_name)                                        | Name of the EKS cluster where Vector going to be installed.                                                                                                                                                                                                                                                                 | `string`      | n/a                 |   yes    |
| <a name="input_elasticsearch_endpoint"></a> [elasticsearch_endpoint](#input_elasticsearch_endpoint)                      | Endpoint of OpenSearch (ElasticSearch) to which we are sending logs in format `https://elasticsearch.example.com:443`.                                                                                                                                                                                                      | `string`      | n/a                 |   yes    |
| <a name="input_helm_chart_config"></a> [helm_chart_config](#input_helm_chart_config)                                     | Helm chart config. Applies to both agent and aggregator. See https://registry.terraform.io/providers/hashicorp/helm/latest/docs                                                                                                                                                                                             | `any`         | `{}`                |    no    |
| <a name="input_name"></a> [name](#input_name)                                                                            | Name or prefix for resources that will be created.                                                                                                                                                                                                                                                                          | `string`      | `"vector"`          |    no    |
| <a name="input_s3_bucket_name"></a> [s3_bucket_name](#input_s3_bucket_name)                                              | By default S3 bucket name generates as `$var.name-$var.eks_cluster_name-logs`. You can override it here by providing custom name.                                                                                                                                                                                           | `string`      | `null`              |    no    |
| <a name="input_s3_bucket_policy"></a> [s3_bucket_policy](#input_s3_bucket_policy)                                        | By default we are creating the least priviledgies S3 bucket policy (limited access only for `Agent IAM Role` and `Aggregator IAM Role`). You can override it by providing S3 bucket policy JSON document here.                                                                                                              | `string`      | `null`              |    no    |
| <a name="input_s3_expiration_days"></a> [s3_expiration_days](#input_s3_expiration_days)                                  | How many days keep log files in S3 bucket.                                                                                                                                                                                                                                                                                  | `number`      | `7`                 |    no    |
| <a name="input_s3_force_destroy"></a> [s3_force_destroy](#input_s3_force_destroy)                                        | A boolean that indicates all objects should be deleted from the bucket first to destroy the bucket without error.                                                                                                                                                                                                           | `bool`        | `false`             |    no    |
| <a name="input_secret_name"></a> [secret_name](#input_secret_name)                                                       | Secret which contains `vector_username` and `vector_password` we are using to perform Basic Authenification in OpenSearch (ElasticSearch).                                                                                                                                                                                  | `string`      | `null`              |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                            | A mapping of tags to assign to the resources.                                                                                                                                                                                                                                                                               | `map(string)` | `{}`                |    no    |

## Outputs

| Name                                                                                         | Description                                        |
| -------------------------------------------------------------------------------------------- | -------------------------------------------------- |
| <a name="output_vector_s3_bucket_id"></a> [vector_s3_bucket_id](#output_vector_s3_bucket_id) | S3 bucket created to store logs before they parsed |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
