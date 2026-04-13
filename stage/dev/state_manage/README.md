# state_manage 設計

`state_manage` は、Terraform の remote state 運用に必要な基盤を作る bootstrap stack です。
通常の業務リソース stack とは役割が異なり、S3 backend 用の保存先と lock 機構を先に用意する責務を持ちます。

## 役割

- Terraform state 保存先の S3 バケットを作成する
- Terraform state lock 用の DynamoDB テーブルを作成する
- tfstate バケットに対するセキュリティ設定を適用する
- tfstate バケットの access logging を設定する

## ファイル構成

- `main.tf`
  - state 保存先バケット本体
  - versioning
  - lock 用 DynamoDB table
  - 共通 module / 環境 module の参照
- `s3_security.tf`
  - S3 暗号化
  - public access block
  - ownership controls
  - HTTPS 強制 policy
- `s3_logging.tf`
  - ログ保存用バケット
  - tfstate バケットの access logging
  - ログ削除 lifecycle
- `outputs.tf`
  - bucket 名や ARN
  - DynamoDB table 名や ARN

## 値の流れ

`state_manage` は定数を直接持たず、以下の module から値を受け取ります。

1. `stage/common`
  - `app_name`
  - `aws_region`
2. `stage/dev`
  - `stage`

これらを使って resource 名や provider 設定を構成します。

例:

```hcl
provider "aws" {
  region = module.common.aws_region
}

locals {
  state_bucket_name = "tfstate-${module.common.app_name}-${module.env.stage}"
  lock_table_name   = "tfstate-${module.common.app_name}-lock-${module.env.stage}"
}
```

## remote state 設計

このリポジトリでは、通常 stack は S3 backend を使って state を remote 管理する方針です。
その前提となる bucket と lock table を `state_manage` が作成します。

想定手順:

1. `state_manage` で backend 基盤を作成する
2. `account` `network` `application` などの stack で S3 backend を利用する
3. 必要であれば `state_manage` 自身の state 移行を別途行う

`state_manage` 自体は backend 基盤を作る stack なので、bootstrap の起点として扱います。

## S3 設計

### state バケット

- Terraform state の保存先
- versioning を有効化
- 誤削除防止のため `prevent_destroy` を設定

### ログバケット

- state バケットの access log 保存先
- access log 専用に分離
- lifecycle で一定期間後に自動削除

### セキュリティ設定

- S3 オブジェクトをサーバー側暗号化
- public access を全面 block
- HTTPS 以外のアクセスを deny
- ownership controls を用途に応じて設定

## DynamoDB 設計

- Terraform state lock 用に使用
- `PAY_PER_REQUEST`
- `LockID` を hash key として使用
- point-in-time recovery を有効化
- deletion protection を有効化
