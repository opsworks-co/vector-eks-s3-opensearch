locals {
  default_agent_config = <<EOF
customConfig:
  data_dir: /vector-data-dir
  api:
    enabled: true
    address: 127.0.0.1:8686
    playground: false
  sources:
    kubernetes_logs:
      type: kubernetes_logs
      self_node_name: $${VECTOR_SELF_NODE_NAME:-unspecified}
    # internal_metrics:
    #   type: internal_metrics
  transforms:
    added_cluster_name:
      type: remap
      inputs:
        - kubernetes_logs
      source: |
        .kubernetes.cluster_name = "${var.eks_cluster_name}"
  sinks:
    s3:
      inputs:
        - added_cluster_name
      type: aws_s3
      region: "${data.aws_region.current.name}"
      bucket: "${module.vector_s3_bucket.s3_bucket_id}"
      key_prefix: date=%Y-%m-%d/
      encoding:
        codec: json

tolerations:
  - effect: NoSchedule
    operator: Exists

# avoid Fargate nodes, we can't deploy DaemonSets there
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: eks.amazonaws.com/compute-type
          operator: NotIn
          values:
           - "fargate"
EOF

  default_agent_template_vairables = {
    region       = data.aws_region.current.name,
    bucket       = module.vector_s3_bucket.s3_bucket_id
    cluster_name = var.eks_cluster_name
  }

  custom_agent_config = var.agent_template_filename != null ? templatefile(var.agent_template_filename, merge(local.default_agent_template_vairables, var.agent_template_variables)) : local.default_agent_config

  agent_values = {
    role = "Agent"
    serviceAccount = {
      annotations = {
        "eks.amazonaws.com/role-arn" = module.vector_agent_role.iam_role_arn
      }
    }
  }
}

data "utils_deep_merge_yaml" "values_agent_merged" {
  input = [
    local.custom_agent_config,
    yamlencode(local.agent_values),
    yamlencode(try(var.agent_values_override, {}))
  ]
}

resource "helm_release" "vector_agent" {
  name             = "vector-agent"
  chart            = local.helm_chart_config.chart
  repository       = local.helm_chart_config.repository
  version          = local.helm_chart_config.version
  namespace        = local.helm_chart_config.namespace
  create_namespace = local.helm_chart_config.create_namespace

  values = [data.utils_deep_merge_yaml.values_agent_merged.output]
}

data "aws_iam_policy_document" "vector_agent" {
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      module.vector_s3_bucket.s3_bucket_arn,
    ]
    effect = "Allow"
  }

  statement {
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${module.vector_s3_bucket.s3_bucket_arn}/*"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "vector_agent" {
  name        = "${data.aws_eks_cluster.eks.id}-vector-agent"
  path        = "/"
  description = "Policy for vector agent pod."

  policy = data.aws_iam_policy_document.vector_agent.json
  tags   = var.tags
}

module "vector_agent_role" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "v5.33.0"
  create_role                   = true
  allow_self_assume_role        = false
  role_description              = "Vector Agent IRSA"
  role_name                     = "${data.aws_eks_cluster.eks.name}-vector-agent"
  provider_url                  = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
  role_policy_arns              = [aws_iam_policy.vector_agent.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.helm_chart_config.namespace}:vector-agent"]
  tags                          = var.tags
}
