# ---------------------------------------------------------------------------
# Metrics and dashboards: Prometheus, Alertmanager, Grafana
# ---------------------------------------------------------------------------
resource "random_password" "grafana" {
  length  = 20
  special = false
}

resource "helm_release" "prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = try(var.chart_versions["prometheus_stack"], null)
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 900

  values = [yamlencode({
    grafana = {
      adminPassword = random_password.grafana.result
      ingress = {
        enabled          = true
        ingressClassName = "alb"
        hosts            = [var.grafana_hostname]
        path             = "/"
        pathType         = "Prefix"
        annotations = {
          "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"      = "ip"
          "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
          "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
          "alb.ingress.kubernetes.io/certificate-arn"  = var.certificate_arn
          "alb.ingress.kubernetes.io/healthcheck-path" = "/api/health"
        }
      }
    }

    prometheus = {
      prometheusSpec = {
        retention = "7d"
        # Pick up ServiceMonitors and PodMonitors from any namespace, including the app's.
        serviceMonitorSelectorNilUsesHelmValues = false
        podMonitorSelectorNilUsesHelmValues     = false
        resources = {
          requests = { cpu = "200m", memory = "512Mi" }
        }
      }
    }

    alertmanager = {
      alertmanagerSpec = {
        resources = {
          requests = { cpu = "50m", memory = "64Mi" }
        }
      }
    }
  })]
}

# ---------------------------------------------------------------------------
# Logs: Fluent Bit ships container logs to CloudWatch
# ---------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "containers" {
  name              = "/eks/${var.cluster_name}/containers"
  retention_in_days = var.log_retention_days
}

data "aws_iam_policy_document" "fluent_bit" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:PutRetentionPolicy",
    ]
    resources = [
      aws_cloudwatch_log_group.containers.arn,
      "${aws_cloudwatch_log_group.containers.arn}:*",
    ]
  }
}

resource "aws_iam_policy" "fluent_bit" {
  name   = "${var.cluster_name}-fluent-bit"
  policy = data.aws_iam_policy_document.fluent_bit.json
}

module "fluent_bit_role" {
  source = "../irsa"

  role_name                  = "${var.cluster_name}-fluent-bit"
  oidc_provider_arn          = var.oidc_provider_arn
  namespace_service_accounts = ["logging:aws-for-fluent-bit"]
  role_policy_arns = {
    cloudwatch_logs = aws_iam_policy.fluent_bit.arn
  }
}

resource "helm_release" "fluent_bit" {
  name             = "aws-for-fluent-bit"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-for-fluent-bit"
  version          = try(var.chart_versions["fluent_bit"], null)
  namespace        = "logging"
  create_namespace = true

  values = [yamlencode({
    serviceAccount = {
      create = true
      name   = "aws-for-fluent-bit"
      annotations = {
        "eks.amazonaws.com/role-arn" = module.fluent_bit_role.role_arn
      }
    }

    cloudWatchLogs = {
      enabled         = true
      region          = var.region
      logGroupName    = aws_cloudwatch_log_group.containers.name
      autoCreateGroup = false
    }

    # The chart's CloudWatch plugin is the older one; keep only the logs plugin on.
    cloudWatch    = { enabled = false }
    firehose      = { enabled = false }
    kinesis       = { enabled = false }
    elasticsearch = { enabled = false }
  })]
}
