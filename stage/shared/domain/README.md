# domain 設計

`domain` は、`shared` 領域で利用する Route53 hosted zone と ACM 証明書を管理する stack です。
`application` stack が利用するドメイン名と証明書 ARN の土台を先に提供する責務を持ちます。

## 役割

- ルートドメインの hosted zone を管理する
- front 用ドメインと API 用ドメインを定義する
- ACM 証明書を front 用 / API 用で発行する
- DNS 検証レコードを Route53 に作成する
- 後続 stack が参照する zone ID / certificate ARN を出力する

## 設計方針

- DNS と証明書は手運用ではなく Terraform で一元管理する
- `shared` stack として backend を `tfstate-billingrse-shared` に集約する
- CloudFront 用証明書は `us-east-1`、ALB/API 用証明書は `ap-northeast-1` で分離する
- hosted zone は Terraform で新規作成する
- 証明書検証は DNS validation を採用し、自動更新に追従しやすい構成にする

## ドメイン命名方針

この stack では以下の命名ルールでドメインを構成する。

- root domain: `root_domain_name`（例: `shrimptail.net`）
- front domain: `<env_subdomain>.<root_domain_name>`（例: `dev.shrimptail.net`）
- api domain: `api.<env_subdomain>.<root_domain_name>`（例: `api.dev.shrimptail.net`）

入力値:

- `env_subdomain`
- `root_domain_name` は `stage/common` の定数を使用する
- `aws_region` は `stage/common` の定数を使用する

## 証明書設計

### front 用証明書

- 用途: CloudFront
- リージョン: `us-east-1`
- 対象 FQDN: `<env_subdomain>.<root_domain_name>`
- 検証方式: DNS validation

### API 用証明書

- 用途: ALB / API endpoint
- リージョン: `ap-northeast-1`
- 対象 FQDN: `api.<env_subdomain>.<root_domain_name>`
- 検証方式: DNS validation

### ライフサイクル方針

- 証明書リソースは `create_before_destroy = true` とし、更新時の中断リスクを下げる
- 検証レコードは ACM の `domain_validation_options` から動的生成する

## DNS 検証フロー

1. ACM 証明書を申請する
2. ACM が要求する DNS 検証レコードを Route53 に作成する
3. `aws_acm_certificate_validation` で検証完了を待機する
4. 検証済みの証明書 ARN を outputs で公開する

この設計により、証明書更新時の検証レコード管理を Terraform 側に閉じ込める。

## Hosted Zone 運用方針

- `aws_route53_zone` を Terraform で新規作成する
- 既存 hosted zone の import は本構成では前提にしない
- NS 委譲やレジストラ側設定は AWS 外の作業が必要なため、運用手順として別管理する

## backend / state 方針

- backend: S3 (`tfstate-billingrse-shared`)
- lock: DynamoDB (`tfstate-billingrse-lock-shared`)
- key: `domain/terraform.tfstate`

state 基盤は `stage/shared/state_manage` で事前に作成する前提。

## ファイル構成

- `main.tf`
  - backend / provider 設定
  - Route53 hosted zone
  - front / API 用 ACM 証明書
  - DNS validation record と certificate validation
- `variables.tf`
  - `env_subdomain`
- `outputs.tf`
  - hosted zone 情報
  - front / API の domain 名
  - front / API の certificate ARN

## 外部公開する値

`domain` stack は、後続 stack が参照するドメイン関連情報を `outputs.tf` から公開する。

主な公開値:

- `route53_zone_id`
- `route53_zone_arn`
- `route53_name_servers`
- `front_domain_name`
- `api_domain_name`
- `front_certificate_arn`
- `api_certificate_arn`

## 未採用とした構成

### 手動証明書運用

理由:

- 更新漏れや検証漏れの運用リスクが高い
- 環境差分が発生しやすく再現性を保ちにくい

### DNS を外部管理のまま固定

理由:

- 証明書 DNS 検証を Terraform で自動化しにくい
- stack 間依存（domain -> application）の一貫性が崩れやすい
