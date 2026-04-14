data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# OIDC用のプロバイダー
data "http" "github_actions_openid_configuration" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

data "tls_certificate" "github_actions" {
  url = jsondecode(data.http.github_actions_openid_configuration.response_body).jwks_uri
}

resource "aws_iam_openid_connect_provider" "github_actions" {
  count = var.github_actions_oidc_provider_arn == null ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.github_actions.certificates[*].sha1_fingerprint
}

locals {
  github_actions_oidc_provider_arn = var.github_actions_oidc_provider_arn != null ? var.github_actions_oidc_provider_arn : aws_iam_openid_connect_provider.github_actions[0].arn
  cicd_ecr_repository_arns = [
    for name in local.ecr_repository_names :
    "arn:aws:ecr:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:repository/${name}"
  ]
}

# ロールの作成
data "aws_iam_policy_document" "billingrse_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.github_actions_oidc_provider_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.github_repo_subjects
    }
  }
}

resource "aws_iam_role" "cicd" {
  name               = "${local.deploy_name}-cicd-role"
  assume_role_policy = data.aws_iam_policy_document.billingrse_assume_role_policy.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "cicd" {
  statement {
    sid = "EcrAuthDescribe"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:DescribeRepositories"
    ]
    resources = ["*"]
  }
  statement {
    sid = "EcrPushPull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = local.cicd_ecr_repository_arns
  }
  statement {
    sid = "EcrCreateRepository"
    actions = [
      "ecr:CreateRepository"
    ]
    resources = ["*"]
  }
  statement {
    sid = "EcsDescribeNetworkForDeploy"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups"
    ]
    resources = ["*"]
  }
  statement {
    sid = "EcsServiceDeploy"
    actions = [
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:RunTask",
      "ecs:UpdateService",
      "ecs:DescribeServices",
      "ecs:DescribeClusters",
      "ecs:DescribeTaskDefinition",
      "ecs:ListTaskDefinitions"
    ]
    resources = ["*"]
  }
  statement {
    sid = "FrontS3DeployList"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.front_bucket_name}"
    ]
  }
  statement {
    sid = "FrontS3DeployObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${local.front_bucket_name}/*"
    ]
  }
  statement {
    sid = "CloudFrontInvalidate"
    actions = [
      "cloudfront:ListDistributions",
      "cloudfront:CreateInvalidation"
    ]
    resources = ["*"]
  }
  statement {
    sid = "EcsPassRoles"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      aws_iam_role.ecs_task_execution.arn,
      aws_iam_role.ecs_task.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "cicd" {
  name   = "${local.deploy_name}-cicd-policy"
  policy = data.aws_iam_policy_document.cicd.json
}

resource "aws_iam_role_policy_attachment" "cicd" {
  role       = aws_iam_role.cicd.name
  policy_arn = aws_iam_policy.cicd.arn
}
