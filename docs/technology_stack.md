# 技術スタック

このドキュメントは、`billingrse` IaC リポジトリで利用している技術スタックをまとめたものです。

## 対象範囲

- 本リポジトリ（`infra`）で管理している IaC / インフラ運用 / CI ワークフロー
- アプリ本体（backend / frontend）の実装ライブラリは対象外

## 使用言語・記述形式

- Terraform（HCL）
- YAML（GitHub Actions, Taskfile）
- Shell Script（Bash）
- SQL（DB 初期化用）

## IaC

- Terraform: `>= 1.6.0`
- Provider: `hashicorp/aws` `6.25.0`
- State 管理:
  - S3（tfstate 保存）
  - DynamoDB（state lock）

## AWS サービス

### ネットワーク

- VPC
- Subnet（public / private db）
- Route Table / Route Table Association
- Internet Gateway
- Security Group

### 配信・アプリ実行

- Application Load Balancer（ALB）
- ECS（Cluster / Service / Task Definition）
- ECR
- CloudFront
- S3（静的配信）

### データ・連携

- RDS（MySQL）
- Service Discovery（Cloud Map / Private DNS）
- Route53
- ACM
- SES
- Secrets Manager（アプリ側連携前提）

### 認証・権限・監視

- IAM（Role / Policy / OIDC）
- CloudWatch Logs

## CI/CD・運用ツール

- GitHub Actions
- Docker
- AWS CLI
- jq（Task Definition JSON 操作）
- Taskfile（ローカル運用補助）

## GitHub Actions（infra リポジトリ）

- `ecr_push_redis.yml`
  - `redis:8.4-alpine` をベースに Redis イメージを作成し、ECR へ push
- `ecr_push_db_init.yml`
  - `ecr_image/db_init` の Dockerfile を build し、ECR へ push
- `run_db_init_task.yml`
  - ECS Fargate の db-init タスクを手動実行

### 主な Action

- `actions/checkout@v4`
- `aws-actions/configure-aws-credentials@v4`
- `aws-actions/amazon-ecr-login@v2`

## 関連リポジトリ（参考）

- backend: <https://github.com/shrimptails-f/billingrse_backend>
- frontend: <https://github.com/shrimptails-f/billingrse_front>
