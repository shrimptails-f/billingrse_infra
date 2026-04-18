# stage ディレクトリ

ステージごとのエントリーポイントを配置します。`dev/` 配下は以下の構成です。

- `dev/state_manage/` : tfstate 保存用の S3 バケットとロック用 DynamoDB を作成
- `dev/network/` : VPC/サブネット/SG などを modules/network からデプロイ（S3 backend）
- `dev/account/` : アカウント共通リソースと ECR を modules/account からデプロイ（S3 backend）
- `dev/application/` : アプリ本体を modules/application からデプロイ（network の remote state を参照）

stg/prd を追加する場合はこの構成をコピーし、`stage` 変数や backend 設定をステージごとに調整してください。
