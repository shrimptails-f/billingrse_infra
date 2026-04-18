# application module

- `alb.tf`: ALB 本体とリスナー（SG/TG は network 側から入力）
- `ec2_asg.tf`: アプリ用 SG（入力）、Launch Template、Auto Scaling Group
- `db.tf`: RDS Subnet Group、DB インスタンス（SG は入力）
- `s3_front.tf`: フロント用 S3 バケットと公開設定
- `variables.tf`: 共通/ネットワーク依存/アプリ依存の入力定義
