# network module

- `vpc.tf`: VPC と IGW
- `subnets.tf`: Public / Private(db) サブネット
- `routes.tf`: Public / Private(db) ルートテーブルと関連付け
- `sg_tg.tf`: ALB / App / DB / Redis のセキュリティグループと App 用ターゲットグループ
- `outputs.tf`: 各種 ID/ARN を外部公開（VPC, Subnet, SG, TG など）
