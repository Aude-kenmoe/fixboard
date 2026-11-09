resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = "argocd"
  create_namespace = true

  values = [yamlencode({
    global = {
      domain = var.hostname
    }

    configs = {
      params = {
        # TLS ends at the load balancer, so the server speaks plain HTTP behind it.
        "server.insecure" = true
      }

      cm = {
        # A token-only account for the pipeline: it cannot sign in to the UI.
        "accounts.ci" = "apiKey"
      }

      rbac = {
        # The ci account may read and sync the fixboard application, nothing else.
        "policy.csv" = join("\n", [
          "p, role:ci, applications, get, default/fixboard, allow",
          "p, role:ci, applications, sync, default/fixboard, allow",
          "g, ci, role:ci",
        ])
      }
    }

    server = {
      ingress = {
        enabled          = true
        ingressClassName = "alb"
        annotations = {
          "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"      = "ip"
          "alb.ingress.kubernetes.io/listen-ports"     = jsonencode([{ HTTP = 80 }, { HTTPS = 443 }])
          "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
          "alb.ingress.kubernetes.io/certificate-arn"  = var.certificate_arn
          "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
          "alb.ingress.kubernetes.io/healthcheck-path" = "/healthz"
        }
      }
    }
  })]
}
