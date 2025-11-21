resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
    labels = {
      name        = var.argocd_namespace
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "aws_iam_role" "argocd_role" {
  name = "${var.cluster_name}-${var.environment}-argocd-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = var.oidc_provider_arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:${var.argocd_namespace}:argocd-application-controller"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Component   = "ArgoCD"
  }
}

resource "aws_iam_role_policy" "argocd_ecr_policy" {
  name = "${var.cluster_name}-${var.environment}-argocd-ecr-policy"
  role = aws_iam_role.argocd_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "helm_release" "argocd" {
  name      = "argocd-${var.environment}"
  namespace = kubernetes_namespace.argocd.metadata[0].name
  chart     = "${path.module}/../../../charts/argocd"

  values = [
    file("${path.module}/../../../charts/argocd/values.yaml"),
    file("${path.module}/../../../charts/argocd/values-${var.environment}.yaml"),
    yamlencode({
      environment = var.environment
      gitRepository = {
        url = var.git_repository_url
        credentials = {
          enabled  = var.github_token != "" ? true : false
          username = var.github_username
          password = var.github_token
        }
      }
      "argo-cd" = {
        controller = {
          serviceAccount = {
            annotations = {
              "eks.amazonaws.com/role-arn" = aws_iam_role.argocd_role.arn
            }
          }
        }
        configs = var.argocd_admin_password != "" ? {
          secret = {
            argocdServerAdminPassword = var.argocd_admin_password
          }
        } : {}
      }
    })
  ]

  depends_on = [
    kubernetes_namespace.argocd
  ]
}

