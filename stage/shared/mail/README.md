# mail 設計

`mail` は、`shared` 領域で利用する SES 送信基盤と、その成立に必要な DNS レコードを管理する stack です。
`application` stack がメール送信を行うための土台を先に提供し、`account` stack がその利用権限を付与する前提の責務を持ちます。

## 役割

- SES の送信元ドメイン identity を管理する
- SES domain verification 用の DNS レコードを管理する
- DKIM 用の DNS レコードを管理する
- DMARC など送信ドメイン運用に必要な DNS レコードを管理する
- 後続 stack が参照する SES identity 情報を出力する

## 設計方針

- メール送信基盤は `application` や `account` に混在させず、`shared` stack として分離する
  - SES はアプリ実行設定だけでなく DNS 検証や送信ドメイン運用を含むため、共有基盤として切り出した方が責務が明確になるため
- DNS と密接に結びつく要素は `shared` 側で一元管理する
  - DKIM、MAIL FROM、DMARC などは Route53 レコード管理と不可分であり、DNS 管理責務の近くに置く方が保守しやすいため
- SES identity は環境単位のサブドメインで分離する
  - `dev` と `prod` の送信経路や reputation 影響範囲を分け、環境間の誤送信リスクも下げやすくするため
- DNS レコードは手運用ではなく Terraform で管理する
  - DKIM や verification レコードの追加漏れを防ぎ、環境差分のない再現可能な運用にしたいため
- 送信権限は `account` stack、実行時設定は `application` stack に分離する
  - IAM とアプリ設定の変更頻度や責務が異なるため、既存 stack 境界に合わせて分離した方が変更影響を局所化できるため

## stack 境界

この機能は以下の責務分担で管理する。

- `stage/shared/domain`
  - Route53 hosted zone を管理する
  - front / API 用 ACM 証明書を管理する
- `stage/shared/mail`
  - SES identity
  - DKIM
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

採用理由:

- `dev` と `prod` の送信基盤を論理的に分離しやすいため
- 開発環境の誤送信や reputation 影響を本番と分けやすいため
- 既存の `env_subdomain` ベース設計と整合するため

## SES 設計

### Domain Identity

- SES の送信元 identity は `<env_subdomain>.<root_domain_name>` を使う
- 送信リージョンはアプリケーション実行リージョンに合わせて `ap-northeast-1` を前提とする
- identity の作成と検証用 DNS レコード管理はこの stack の責務とする
- Terraform リソースとして `aws_ses_domain_identity` を作成する

採用理由:

- ドメイン単位で `no-reply@dev.shrimptail.net` のような送信元を扱え、環境内で複数の送信アドレスを運用しやすいため
- SES の DNS 検証フローを Terraform に閉じ込めやすいため

### DKIM

- Easy DKIM を利用する
- SES が要求する 3 本の CNAME を Route53 に作成する
- DKIM レコードも Terraform で管理し、手動追加を前提にしない

採用理由:

- 秘密鍵を自前管理せずに DKIM 署名を有効化でき、初期導入の複雑さを下げられるため
- SES 標準の運用に寄せることで、鍵管理の責務を Terraform やアプリに持ち込まずに済むため

### DMARC

- `_dmarc.<env_subdomain>.<root_domain_name>` に TXT レコードを作成する
- 初期ポリシーは `p=none` で開始する
- 問題がないことを確認できたら、段階的に `p=quarantine`、`p=reject` へ強化する
- レポート送信先を使う場合も、この stack でレコード値を管理する

運用方針:

- 初期段階では受信拒否を行わず、配信影響を観測する
- DKIM と送信運用の整合が確認できた後に段階的に強化する
- ポリシー変更も Terraform 管理とし、手動変更を前提にしない

## DNS レコード方針

この stack で管理する主なレコードは以下。

- SES verification 用 TXT
- DKIM 用 CNAME 3 本
- DMARC 用 TXT

Route53 hosted zone 自体の管理は `stage/shared/domain` の責務とし、この stack はその zone を参照してレコードのみを追加する。

## shared/domain との接続

- Route53 hosted zone ID は `terraform_remote_state` で `stage/shared/domain` の output から取得する
- root domain 名は `stage/common` を module 参照して取得する

採用理由:

- zone の実体管理責務を `shared/domain` に残したまま、`shared/mail` から必要最小限の参照だけを行えるため
- root domain の定数は既存ルールどおり `stage/common` に寄せた方が、ドメイン名の重複定義を避けられるため

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
このとき権限範囲は広く取らず、`no-reply@dev.shrimptail.net` のような許可済み送信元アドレスに限定する前提とする。

採用理由:

- アプリケーションが意図しない送信元アドレスを使うことを防ぎ、誤送信や設定ミスの影響範囲を小さくするため
- dev 環境では送信用途を限定した方が、運用監査や後続の本番設計へ移行しやすいため

### `stage/dev/application` へ渡すもの

- 送信元メールアドレスの命名方針
- 必要に応じて configuration set 名

`application` stack は SES リソース自体を作らず、`EMAIL_FROM_ADDRESS` などの実行時設定だけを持つ。

## 出力方針

主に以下の値を `outputs.tf` から公開する想定とする。

- `ses_domain_identity_arn`
- `ses_domain_name`
- `dmarc_domain_name`
- `ses_configuration_set_name`（利用する場合）

## Configuration Set 方針

- configuration set は今回の実装対象に含める方向で設計する
- 初期段階では複雑な送信ルールを持たせず、将来のイベント連携や送信制御を載せられる受け皿として作成する
- `application` stack から必要であれば設定名を参照できるようにする

採用理由:

- 現時点で必須の高度な制御がなくても、後からイベント連携や送信制限を追加しやすい基盤を先に用意できるため
- SES 関連の運用設定をメール基盤側へ寄せ、アプリ側の変更を最小化しやすくするため

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
  - DMARC などの設定値
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
- DKIM や DMARC の DNS レコード管理を自然に置きにくいため
