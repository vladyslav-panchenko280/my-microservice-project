# Storage class for Jenkins persistent volume
resource "kubernetes_storage_class_v1" "ebs_sc" {
  metadata {
    name = "ebs-sc"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"

  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type = "gp3"
  }
}

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = "jenkins"
    labels = {
      name        = "jenkins"
      environment = var.environment
    }
  }
}

resource "kubernetes_service_account" "jenkins_sa" {
  metadata {
    name      = "jenkins-sa"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.jenkins_kaniko_role.arn
    }
  }
}

resource "aws_iam_role" "jenkins_kaniko_role" {
  name = "${var.cluster_name}-${var.environment}-jenkins-kaniko-role"

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
            "${replace(var.oidc_provider_url, "https://", "")}:sub" = "system:serviceaccount:jenkins:jenkins-sa"
          }
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy" "jenkins_ecr_policy" {
  name = "${var.cluster_name}-${var.environment}-jenkins-ecr-policy"
  role = aws_iam_role.jenkins_kaniko_role.id

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
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "kubernetes_secret" "github_credentials" {
  count = var.github_token != "" ? 1 : 0

  metadata {
    name      = "github-credentials"
    namespace = kubernetes_namespace.jenkins.metadata[0].name
  }

  data = {
    username = var.github_username
    token    = var.github_token
  }

  type = "Opaque"
}

resource "helm_release" "jenkins" {
  name      = "jenkins-${var.environment}"
  namespace = kubernetes_namespace.jenkins.metadata[0].name
  chart     = "${path.module}/../../../charts/jenkins"

  values = [
    file("${path.module}/../../../charts/jenkins/values.yaml"),
    file("${path.module}/../../../charts/jenkins/values-${var.environment}.yaml"),
    yamlencode({
      environment = var.environment
      jenkins = {
        controller = {
          admin = {
            password = var.jenkins_admin_password
          }
        }
      }
    })
  ]

  depends_on = [
    kubernetes_service_account.jenkins_sa,
    kubernetes_storage_class_v1.ebs_sc,
    kubernetes_secret.github_credentials
  ]
}
