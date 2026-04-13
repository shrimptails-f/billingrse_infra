# billingrseとは

名前はbillingとparserを合わせた造語です。

Gmailから請求メールを取得し、AI解析を行ったうえで保存し、請求を検索・集計できます。  
※本リポジトリは`billingrse`の`IaCリポジトリ`です  
非構造なメール本文を、あとから追跡できる請求データへ変換するためのインフラ構成を管理することを目的にしています。

- 非構造メールを請求データへ変換するサービス基盤を管理
- stage分離で責務を明確化
- remote stateでTerraformの適用単位を分離

## このプロジェクトが解く課題

本プロジェクトは下記課題を解決し、
複数メールサービス・複数アカウントの請求メールを集計・確認するソリューションを支えるインフラを提供します。

- SaaSや各種支払いに関するメールは受信箱に散在しやすく、あとから検索・集計・重複確認しづらい
- 複数メールサービス・複数アカウントにまたがって情報を集約するのが難しい
- メール本文は非構造データなので、そのままでは請求一覧や月次比較に使いづらい
- AI解析だけでは業務データとして不十分で、支払先の正規化、請求成立判定、監査可能な履歴設計が別途必要になる

# 関連リポジトリ
- backend
  - https://github.com/shrimptails-f/billingrse_backend
- frontend
  - https://github.com/shrimptails-f/billingrse_front

# 技術スタック

## 使用言語

- Terraform

## AWS使用サービス一覧

- S3（tfstate/静的サイト/ログ含む）
- SES
- DynamoDB（Stateロック）
- IAM（ユーザー/グループ/OIDCロール/ポリシー）
- ECR（コンテナイメージ）
- VPC/IGW/サブネット/ルートテーブル/NAT Gateway/EIP
- セキュリティグループ
- ALB（リスナー/ターゲットグループ）
- EC2（Launch Template/Auto Scaling Group）
- RDS（DBインスタンス/サブネットグループ）


# 環境構築手順
[こちら](./docs/VsCodeDevContainer.md)を確認してください。

# デプロイ手順
[こちら](./docs/deployment.md)を確認してください。
