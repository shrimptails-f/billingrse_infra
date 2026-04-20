# application 設計

`application` は、`dev` 環境のアプリケーション実行基盤とデータストア、フロント配信基盤をまとめて作る stack です。
この stack は `network` と `account`、`shared/domain` を前提に、その上にアプリケーションを成立させるリソース群を配置します。

## 役割

- ALB を作成し、API の外部入口を提供する
- ECS Fargate で backend アプリケーションを実行する
- RDS を作成し、backend から利用する MySQL を提供する
- ECS Fargate で Redis を実行し、backend から利用する Redis を提供する
- フロントエンド配信用の S3 と CloudFront を作成する
- Route53 の alias record（A）を作成し、フロント系ドメインと API 系ドメインを関連付ける
- アプリケーション運用に必要なログ基盤や補助リソースを作成する

## 設計方針

- `dev` 環境でも本番に近い責務分離を保つ
- ただし `dev` であるため、可用性よりも構成の明快さとコストを優先する
- AZ は単一を前提とする
- public subnet には外部公開や外向き通信が必要なリソースを置く
- private subnet には外部公開しないデータストアを置く
- アプリケーションの入口は ALB に統一し、backend への直接公開はしない
- フロントエンド静的配信は S3 を origin とし、CloudFront を公開入口にする
- アプリケーション実行基盤は ECS Fargate を採用し、EC2 ベースの app サーバーは採用しない
- 証明書、ドメイン、IAM、ECR などの周辺基盤は他 stack の責務とし、この stack では利用に集中する

## 想定構成

構成図の前提は以下です。

- `Route53 -> CloudFront -> S3`
  - フロントエンドの静的コンテンツ配信
- `Route53 -> ALB -> ECS Fargate`
  - API リクエストの処理
- `ECS Fargate -> RDS`
  - アプリケーション DB 接続
- `ECS Fargate -> Redis (ECS Fargate Service)`
  - キャッシュ、セッション、ジョブ制御などの用途
- `ECS Fargate -> Secrets Manager / ECR / SES / 外部 API`
  - アプリ運用に必要な周辺サービス連携

### Redis private 配置時の補足

- Redis タスクは private db subnet (`ap-northeast-1a`) で `assign_public_ip = false`
- `awslogs` ドライバを使うため、CloudWatch Logs へのネットワーク経路が必要
- ECR image pull には `ecr.api/ecr.dkr` に加えて `s3` 経路が必要
- 上記経路は `network` stack の VPC Endpoint と SG で担保する（NAT は使わない）

## サブネット配置

### public subnet

- ALB
- ECS Fargate backend

`dev` 環境では NAT Gateway を前提にせず、アプリケーション実行基盤が外向き通信を行えるよう public subnet 側に配置します。

### private subnet

- RDS
- Redis (ECS Fargate Service)

DB と Redis は外部から直接到達させず、アプリケーションからのみ利用させます。

## 通信設計

- Internet からの API 通信は `ALB -> backend` のみを許可する
- backend から RDS への `3306/tcp` 通信を許可する
- backend から Redis への `6379/tcp` 通信を許可する
- backend から AWS マネージドサービスおよび外部 API への outbound を許可する
- RDS と Redis は Internet から直接到達できない構成にする
- backend への直接 inbound は許可せず、ALB 経由に限定する

## リソース設計

### ALB

- internet-facing の ALB を採用する
- 配置先は public subnet とする
- listener は `80/tcp` と `443/tcp` を持つ
- `80/tcp` は `443/tcp` へリダイレクトする
- ECS backend を target group に登録する
- API 用カスタムドメインは Route53 alias で ALB に向ける

### ECS Fargate backend

- ECS Cluster を作成する
- backend 用 task definition と service を作成する
- backend は ALB 配下で動作させる
- backend コンテナのイメージは ECR から取得する
- ログは CloudWatch Logs に出力する
- 機密情報は Secrets Manager から取得する
- 実行ロールと task role は `account` stack から受け取る
- 外部 API 呼び出しや SES 利用を考慮した IAM 権限を前提にする

### RDS

- MySQL を採用する
- 配置先は private subnet とする
- subnet group は private subnet 用に分離する
- セキュリティグループは backend からの接続だけを許可する
- `dev` 環境では single-AZ とし、過剰な冗長構成は持たない
- マスターパスワードは Secrets Manager 管理を前提とする
- DB の削除保護はオフとする
- 自動バックアップは毎日 1 回取得する
- backup retention period は 7 日とする（7 世代）
- 通常の削除運用では final snapshot を取得しない
- 退避が必要な削除時のみ、可変な `final_snapshot_identifier` を指定して final snapshot を取得する

削除時の運用手順:

- 通常削除（退避不要）
  - `final_snapshot_identifier` を指定せずに `terraform destroy` を実行する
  - final snapshot は作成されず、そのまま削除される
- 退避付き削除（データを残したい）
  - `final_snapshot_identifier` に一意な値（例: `dev-db-final-20260414-01`）を指定して `terraform destroy` を実行する
  - final snapshot 作成完了後に DB が削除される
  - 同じ識別子は再利用できないため、実行のたびに別の値を使う

### Redis on ECS Fargate

- Redis は ECS Fargate サービスとして構築する
- Redis データは揮発する前提で、永続化しない
- 配置先は private subnet とし、`ap-northeast-1a` の private db subnet を使用する
- backend からの Redis ポート通信だけを許可する
- Redis の認証情報は Secrets Manager 等で管理する
- Redis の自動スケールは初期構成では設定しない

### サービス検出（Cloud Map + Route53 Private DNS）

- Redis のサービス検出は AWS Cloud Map を採用する
- private DNS namespace として `billingrse-dev.local` を作成し、`redis.billingrse-dev.local` で名前解決する
- 名前解決は Route53 Private Hosted Zone 経由で行い、インターネット公開はしない
- backend コンテナは `REDIS_HOST=redis.billingrse-dev.local` を利用して Redis に接続する

採用理由:

- `dev` 環境では backend -> redis の単純な接続要件を満たせれば十分であり、Cloud Map の DNS ベース検出で要件を満たせるため
- Service Connect のようなサイドカー常駐構成を避け、構成の単純さとコストを優先するため
- サービス検出トラフィックの詳細ログ収集が弱くても、開発環境では運用上の許容範囲と判断するため

### S3 + CloudFront

- フロントエンド配信用の S3 bucket を作成する
- S3 bucket の versioning は無効（未設定）とする
- S3 bucket の lifecycle ルールは設定しない
- bucket は直接公開せず、CloudFront Origin Access Control 経由で配信する
- CloudFront を外部公開の正規入口にする
- Route53 alias でフロントドメインを CloudFront に向ける
- ACM 証明書は `shared/domain` 側で払い出したものを利用する
- SPA を前提に、`index.html` へのフォールバックを考慮する

### Route53

- フロント用ドメインは CloudFront に A alias する
- API 用ドメインは ALB に A alias する
- AAAA レコードはこの stack では作成しない
- DNS と証明書の責務は `shared/domain` に寄せ、この stack では record 関連のみを扱う

### ログ

- ALB、ECS、Redis、DB 初期化処理など、運用上必要なログ出力先を用意する
- ECS のアプリログは CloudWatch Logs を基本とする
- 保持期間は `dev` に見合う短めの設定を基本とする
- Redis タスクも `awslogs` を使用するため、private subnet 運用時は `logs` Interface Endpoint を前提とする

### SES 利用方針

- backend がメール送信を行う前提で、アプリケーション実行ロールに `ses:SendEmail` などの必要権限を付与する
- SES identity やドメイン検証、送信元アドレスの運用は application の責務として扱う

## 依存関係

`application` stack は以下を前提にする。

- `stage/dev/network`
  - VPC ID
  - public subnet ID
  - private subnet ID
  - ALB 用 security group ID
  - app 用 security group ID
  - RDS 用 security group ID
  - Redis 用 security group ID
  - target group ARN
- `stage/dev/account`
  - ECS task execution role ARN
  - ECS task role ARN
  - backend 用 ECR repository URL
- `stage/shared/domain`
  - フロントドメイン名
  - API ドメイン名
  - ACM 証明書 ARN
  - Route53 hosted zone ID

`application` stack は `terraform_remote_state` で `stage/shared/domain` の output を参照し、ドメイン関連値を自動取得する。
`front_domain_name` などの変数は、必要な場合の上書き用途として扱う。

## 外部公開する値

後続の運用やデプロイで参照しやすいよう、主に以下を `outputs.tf` から公開する。

- ALB DNS 名
- ECS cluster 名
- backend service 名
- RDS endpoint
- Redis service 名または接続先情報
- フロント S3 bucket 名
- CloudFront distribution ID
- CloudFront domain 名
- DB 初期化 task definition ARN

## ファイル構成

- `main.tf`
  - backend / provider 設定
  - `network` / `account` / `shared/domain` の参照
  - `modules/application` 呼び出し
- `variables.tf`
  - image tag や task size、DB 設定、ドメイン関連など外部入力を定義
- `outputs.tf`
  - 他 stack や運用で参照する値を公開

## 未採用とする構成

### app サーバーの EC2 常駐運用

理由:

- 構成図では backend 実行基盤を ECS Fargate としているため
- `dev` でも app 実行環境はコンテナに寄せたほうが運用差分を減らしやすいため

### Redis の ElastiCache 採用

理由:

- コスト削減の観点で採用を見送った
- 可用性が下がるが、運用で十分対応可能な規模と判断した。

### Redis on EC2

理由:

- Redis は揮発データ専用で、永続化を前提にしないため
- アプリ規模が小さく、Redis のスケールを初期要件に含めないため
- EC2 の OS 運用を持たず、運用コストを下げたいため

### RDS の削除保護をオンにする構成

理由:

- `dev` 環境ではコスト削減のため、不要時に DB を削除できる運用を優先するため
- 削除保護をオンにすると、`terraform destroy` 時の運用が重くなるため

### フロントエンドの ALB 配信

理由:

- S3 をグローバルに公開したくないため
- 静的配信は object storage と CDN に寄せるほうが役割が明確なため
