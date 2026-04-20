# network module

- `vpc.tf`: VPC と IGW
- `subnets.tf`: Public / Private(db) サブネット
- `routes.tf`: Public / Private(db) ルートテーブルと関連付け
- `sg_tg.tf`: ALB / App / DB / Redis のセキュリティグループと App 用ターゲットグループ
- `vpc_endpoints.tf`: ECR/CloudWatch Logs(S3 含む) 到達用の VPC Endpoint と VPCE 用 SG
- `outputs.tf`: 各種 ID/ARN を外部公開（VPC, Subnet, SG, TG など）

## Redis (private subnet) の疎通設計

Redis タスクは `assign_public_ip = false` で private subnet に配置するため、
NAT Gateway を使わずに以下の経路で ECS 起動時の通信を成立させる。

- Interface Endpoint
  - `com.amazonaws.<region>.ecr.api`
  - `com.amazonaws.<region>.ecr.dkr`
  - `com.amazonaws.<region>.logs` (`awslogs` 用)
- Gateway Endpoint
  - `com.amazonaws.<region>.s3` (ECR layer download 用)

最小化のため、Interface Endpoint は `private_db["a"]` のみ配置する。

## セキュリティグループ方針（最小許可）

- `vpce` SG ingress: `443/tcp` を `redis` SG からのみ許可
- `redis` SG egress:
  - `443/tcp` -> `vpce` SG
  - `443/tcp` -> S3 prefix list (`com.amazonaws.<region>.s3`)
