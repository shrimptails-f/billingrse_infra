# mail 設計

`mail` は、`shared` 領域で利用する SES 送信基盤と、その成立に必要な DNS レコードを管理する stack です。
`application` stack がメール送信を行うための土台を先に提供し、`account` stack がその利用権限を付与する前提の責務を持ちます。

## 役割

- SES の送信元ドメイン identity を管理する
- SES domain verification 用の DNS レコードを管理する
- DKIM 用の DNS レコードを管理する
- custom MAIL FROM 用の DNS レコードを管理する
- DMARC など送信ドメイン運用に必要な DNS レコードを管理する
- 後続 stack が参照する SES identity 情報を出力する

## 設計方針

- メール送信基盤は `application` や `account` に混在させず、`shared` stack として分離する
- DNS と密接に結びつく要素は `shared` 側で一元管理する
- SES identity は環境単位のサブドメインで分離する
- DNS レコードは手運用ではなく Terraform で管理する
- 送信権限は `account` stack、実行時設定は `application` stack に分離する

## stack 境界

この機能は以下の責務分担で管理する。

- `stage/shared/domain`
  - Route53 hosted zone を管理する
  - front / API 用 ACM 証明書を管理する
- `stage/shared/mail`
  - SES identity
  - DKIM
  - custom MAIL FROM
  - DMARC
  - メール送信基盤に必要な DNS レコード
- `stage/dev/account`
  - ECS task role に SES 利用権限を付与する
- `stage/dev/application`
  - `EMAIL_FROM_ADDRESS` などアプリ実行時の設定を渡す

この分離により、DNS とメール基盤の責務を `shared` に寄せつつ、IAM とアプリ設定の責務を既存 stack に残す。

## ドメイン設計

SES 送信ドメインは root domain 直下ではなく、環境ごとのサブドメインを利用する。

- root domain: `root_domain_name`（例: `shrimptail.net`）
- mail domain: `<env_subdomain>.<root_domain_name>`（例: `dev.shrimptail.net`）
- from address: `no-reply@<env_subdomain>.<root_domain_name>`（例: `no-reply@dev.shrimptail.net`）
- custom MAIL FROM domain: `bounce.<env_subdomain>.<root_domain_name>`（例: `bounce.dev.shrimptail.net`）

採用理由:

- `dev` と `prod` の送信基盤を論理的に分離しやすいため
- 開発環境の誤送信や reputation 影響を本番と分けやすいため
- 既存の `env_subdomain` ベース設計と整合するため

## SES 設計

### Domain Identity

- SES の送信元 identity は `<env_subdomain>.<root_domain_name>` を使う
- 送信リージョンはアプリケーション実行リージョンに合わせて `ap-northeast-1` を前提とする
- identity の作成と検証用 DNS レコード管理はこの stack の責務とする

### DKIM

- Easy DKIM を利用する
- SES が要求する 3 本の CNAME を Route53 に作成する
- DKIM レコードも Terraform で管理し、手動追加を前提にしない

### Custom MAIL FROM

- MAIL FROM ドメインは `bounce.<env_subdomain>.<root_domain_name>` を採用する
- 必要な MX / TXT レコードを Route53 に作成する
- SPF は MAIL FROM ドメイン側に設定する

### DMARC

- `_dmarc.<env_subdomain>.<root_domain_name>` に TXT レコードを作成する
- 初期ポリシーは厳しすぎる設定を避け、段階的に強化できる形を前提とする
- レポート送信先を使う場合も、この stack でレコード値を管理する

## DNS レコード方針

この stack で管理する主なレコードは以下。

- SES verification 用 TXT
- DKIM 用 CNAME 3 本
- custom MAIL FROM 用 MX
- custom MAIL FROM 用 SPF(TXT)
- DMARC 用 TXT

Route53 hosted zone 自体の管理は `stage/shared/domain` の責務とし、この stack はその zone を参照してレコードのみを追加する。

## 他 stack との関係

### この stack が前提とするもの

- `stage/shared/domain`
  - Route53 hosted zone ID
  - root domain 運用
- `stage/common`
  - `root_domain_name`
  - `aws_region`

### `stage/dev/account` へ渡すもの

- SES domain identity ARN
- 必要に応じて configuration set 名

`account` stack はこれらを参照し、ECS task role に `ses:SendEmail` や `ses:SendRawEmail` を付与する。

### `stage/dev/application` へ渡すもの

- 送信元メールアドレスの命名方針
- 必要に応じて configuration set 名

`application` stack は SES リソース自体を作らず、`EMAIL_FROM_ADDRESS` などの実行時設定だけを持つ。

## 出力方針

主に以下の値を `outputs.tf` から公開する想定とする。

- `ses_domain_identity_arn`
- `ses_domain_name`
- `mail_from_domain`
- `dmarc_domain_name`
- `ses_configuration_set_name`（利用する場合）

## backend / state 方針

- backend: S3 (`tfstate-billingrse-shared`)
- lock: DynamoDB (`tfstate-billingrse-lock-shared`)
- key: `mail/terraform.tfstate`

state 基盤は `stage/shared/state_manage` で事前に作成する前提。

## ファイル構成

- `main.tf`
  - backend / provider 設定
  - `stage/common` / `stage/shared/domain` の参照
  - SES identity と DNS record 作成
- `variables.tf`
  - `env_subdomain`
  - DMARC や MAIL FROM の設定値
- `outputs.tf`
  - 後続 stack が参照する SES 関連値を公開

## 運用上の注意

- SES アカウントが sandbox の場合、実運用前に sandbox 解除申請が必要
- DMARC は初手で強い reject を入れず、段階的に強化する方針を前提とする
- dev 環境の送信ドメインは本番と分離し、運用上の影響範囲を限定する

## 未採用とした構成

### `application` stack で SES と DNS を同時に管理する構成

理由:

- アプリ実行基盤と DNS 管理の責務が混ざるため
- Route53 への依存が `application` に漏れ、stack 境界が崩れるため

### `account` stack で SES identity を管理する構成

理由:

- IAM と DNS / ドメイン管理の責務が混ざるため
- DKIM や MAIL FROM の DNS レコード管理を自然に置きにくいため
