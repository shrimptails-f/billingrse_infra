# account module
- `variables.tf`: AWS 共通パラメータ、backend ECR 名、OIDC/GitHub 設定を定義
- `ecr.tf`: backend 用 ECR リポジトリの作成と scan/lifecycle 設定
- `iam_oidc.tf`: GitHub Actions 用 OIDC プロバイダーと CI/CD ロール設定
- `iam_ecs.tf`: ECS task execution role / task role の作成
- `output.tf`: OIDC、CI/CD role、ECS role、backend ECR の出力を公開
