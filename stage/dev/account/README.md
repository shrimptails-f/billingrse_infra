# account 設計

`account` は、`dev` 環境のアプリケーション基盤が利用する IAM と ECR を中心に、AWS アカウント境界の権限管理を担う stack です。
アプリケーション実行そのものは `application` stack の責務とし、この stack では「誰が何にアクセスできるか」を定義します。

## 役割

- GitHub Actions から AWS へ接続するための OIDC 連携を構成する
- CI/CD 用の IAM role を作成する
- backend / db-init / redis 用の ECR repository を作成する
- ECS task execution role を作成する
- ECS task role を作成する
- ECS task が Secrets Manager、ECR などを利用するための IAM policy を定義する

## 設計方針

- 認証と認可の責務は `account` stack に集約する
- アプリケーション stack から IAM policy の詳細を隠蔽し、role ARN を受け渡す構成にする
- CI/CD と実行時権限は分離する
- ECR の push/pull 権限は GitHub Actions 側ロールへ寄せる
- ECS task execution role と ECS task role は用途を分離する
- 権限は最小権限を原則とし、必要な AWS サービスに限定して付与する

## 想定構成

周辺要件から、この stack で扱うべき主な対象は以下です。

- GitHub Actions OIDC provider
- GitHub Actions が AssumeRole する CI/CD 用 IAM role
- backend / db-init / redis 用 ECR repository
- ECS task execution role
- ECS task role
- Secrets Manager、CloudWatch Logs などへのアクセス権

## IAM 設計

### GitHub Actions OIDC

- `token.actions.githubusercontent.com` を trust する OIDC provider を利用する
- GitHub リポジトリ単位で `sub` 条件を制御する
- 長期アクセスキーは発行しない
- CI/CD は OIDC による一時クレデンシャル取得を前提とする

### CI/CD 用 IAM role

- GitHub Actions から AssumeRole する
- ECR への push 権限を持つ
- ECS や関連リソースのデプロイに必要な権限を持つ
- 対象リポジトリを `sub` で制限する
- 不要に広い Administrator 権限は付与しない

### ECS task execution role

- ECS/Fargate がタスク起動時に使う role とする
- 主に以下を許可する
  - ECR からの image pull
  - CloudWatch Logs への出力
  - タスク起動に必要な最低限の Secrets 参照
- アプリケーションロジックが使う AWS API 権限はここへ載せない

補足（private subnet Redis 運用）:

- ECR pull は VPC Endpoint 経由を前提とする
- `aws:sourceVpce` 条件を用いた制御により、想定 Endpoint 以外からの ECR pull を拒否する設計を採用する

### ECS task role

- backend や補助タスクが実行時に使う role とする
- 主に以下を許可する
  - Secrets Manager からのシークレット取得
  - 必要に応じた S3、SSM、外部連携前提の補助権限
- DB 初期化タスクや運用タスクもこの role、または派生 role を利用する

## ECR 設計

- repository は backend / db-init / redis 用を作成する
- image scan は有効化する
- lifecycle policy を設定し、古い image を自動削除できるようにする
- lifecycle policy は最新 10 件を保持し、10 件を超えた古い image を削除する
- repository URL は `application` stack や CI/CD から参照できるよう `outputs.tf` で公開する

## Secrets 参照方針

- シークレット値そのものはこの stack で生成しない
- どの role がどの Secret を読めるかをこの stack で定義する
- backend 用、Redis 用、DB 初期化用など、用途別の Secret 名を前提に設計する
- wildcard を使う場合も prefix を限定し、他用途の Secret を広く読めないようにする

## 他 stack との関係

### `application` へ渡すもの

- ECS task execution role ARN
- ECS task role ARN
- ECR repository URL
- 必要に応じて CI/CD 用 role ARN

### この stack が前提とするもの

- `stage/common` / `stage/dev`
  - アプリ名
  - stage 名
  - region
- GitHub 側
  - 対象 organization / repository
  - Actions から払い出される OIDC token

## 外部公開する値

主に以下を `outputs.tf` から公開する。

- OIDC provider ARN
- CI/CD 用 IAM role ARN
- ECS task execution role ARN
- ECS task role ARN
- backend 用 ECR repository URL
- backend 用 ECR repository ARN
- db-init / redis を含む ECR repository は CI/CD ロールの権限対象として管理する

## ファイル構成

- `main.tf`
  - backend / provider 設定
  - `modules/account` 呼び出し
- `variables.tf`
  - AWS account ID、許可する GitHub repository、ECR repository 名などの入力を定義
- `outputs.tf`
  - `application` や CI/CD が参照する role ARN、repository URL を公開

## 未採用とする構成

### IAM ユーザーへの長期アクセスキー配布

理由:

- GitHub Actions からの AWS アクセスは OIDC に統一するため
- 長期クレデンシャルの配布は漏えい面と運用負荷の両面で避けるべきため

### app stack 側での IAM role 直管理

理由:

- 認証認可の責務を `account` に寄せたほうが stack 境界が明確なため
- `application` が実行基盤に集中できるため
