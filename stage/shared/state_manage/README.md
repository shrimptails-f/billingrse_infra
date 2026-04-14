# state_manage (shared)

`state_manage` は、`stage/shared` 用の Terraform remote state 基盤を作る bootstrap stack です。

作成される主なリソース:

- state 保存用 S3 バケット
- state lock 用 DynamoDB テーブル
- state バケット/ログバケットのセキュリティ設定
- state バケット access logging 設定

この stack 適用後、`stage/shared/domain` などの backend から以下を利用します。

- bucket: `tfstate-<app_name>-shared`
- dynamodb table: `tfstate-<app_name>-lock-shared`
