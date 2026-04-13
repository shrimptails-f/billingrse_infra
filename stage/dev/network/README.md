# network 設計

`network` は、`dev` 環境で利用する VPC と subnet、route table、security group などのネットワーク基盤を作る stack です。
`application` stack から参照される前提のため、アプリ本体より先に作成する土台として扱います。

## 役割

- `dev` 環境用 VPC を作成する
- public / private subnet を作成する
- Internet Gateway と route table を構成する
- ALB / app / DB / Redis 用の security group を作成する
- application stack から参照する subnet / security group / target group を出力する

## 設計方針

- `dev` 環境のため、可用性よりもコストを優先する
- 単一 AZ を前提に構成する
- public subnet と private db subnet を分離する
- NAT Gateway は置かない前提で設計する
- VPC Endpoint は初期構成では配置しない
- VPC DNS は有効化する
- Redis は ElastiCache ではなく EC2 上の self-managed Redis を前提とする
- 将来 `application` stack が参照しやすいように、ネットワーク関連の ID は `outputs.tf` から公開する

## CIDR 方針

現時点の設計方針は以下です。

- VPC: `10.0.0.0/20`
- public subnet: `/24`
- private subnet: `/24`

最小構成の `dev` 用途としては十分な余裕を持ちつつ、`/16` ほど大きくしない方針です。

例:

```text
VPC                10.0.0.0/20
public subnet      10.0.0.0/24
private db subnet  10.0.1.0/24
```

## 想定配置

### public subnet

- ALB
- Fargate

### private db subnet

- RDS
- Redis on EC2

`dev` 環境では NAT を置かない前提のため、アプリケーション実行基盤は public subnet に配置し、外向き通信は public IP と Internet Gateway 経由で成立させる。
DB 系リソースは private db subnet に配置し、外部公開しない。

## 通信設計の論点

NAT を置かない前提で、以下の通信を考慮する。

- Internet からのアプリケーション通信は `ALB -> Fargate` を通す
- アプリケーションから DB 系通信は `Fargate -> RDS` と `Fargate -> Redis` のみ許可する
- アプリケーションから AWS マネージドサービスへの通信は public IP と Internet Gateway 経由で行う
- image pull、ログ出力、シークレット参照など、アプリ実装に必要な outbound 通信先は別途洗い出す

この stack では、VPC と subnet の土台に加えて、アプリケーションが利用する基本的な通信境界を管理する。

## Security Group 設計

この stack では、用途ごとに security group を分離し、通信元を明示して許可する。

### ALB 用 security group

- inbound
  - `80/tcp` を `0.0.0.0/0` から許可
  - `443/tcp` を `0.0.0.0/0` から許可
- outbound
  - app 用 security group への `8080/tcp` 通信を許可

### ALB listener 方針

- `80/tcp` は `443/tcp` へリダイレクトする
- 外部公開の入口は HTTPS を基本とする

### app 用 security group

- inbound
  - ALB 用 security group からの `8080/tcp` 通信を許可
- outbound
  - RDS 用 security group への `3306/tcp` 通信を許可
  - Redis 用 security group への `6379/tcp` 通信を許可
  - AWS マネージドサービスや外部 API などへの outbound 通信は `0.0.0.0/0` 宛てで許可する

### RDS 用 security group

- inbound
  - app 用 security group からの `3306/tcp` 通信のみ許可

### Redis 用 security group

- inbound
  - app 用 security group からの `6379/tcp` 通信のみ許可

### 運用方針

- CIDR で広く許可するのではなく、可能な限り security group 参照で制御する
- DB 系リソースには Internet から直接到達できないようにする
- app への直接 inbound は許可せず、ALB 経由に限定する
- SSH 接続は初期構成では前提にしない
- app の外向き通信は、public subnet の route table と public IP により Internet Gateway 経由で到達させる
- RDS 用 security group と Redis 用 security group では outbound ルールを定義しない

## 未採用とした構成

### NAT Gateway

理由:

- `dev` 環境では固定費を抑えることを優先するため
- アプリケーション実行基盤を public subnet に配置し、public IP を付与することで外向き通信を成立させるため
- 現時点では NAT Gateway がないと成立しない要件を前提にしないため

### VPC Endpoint

理由:

- `Fargate` を public subnet に配置し、public IP と Internet Gateway 経由で AWS マネージドサービスへ接続できるため
- `dev` 環境では閉域化よりも構成の単純さとコストを優先するため
- 利用する AWS サービスが固まってから必要最小限で追加したほうが過剰設計を避けやすいため

## ファイル構成

- `main.tf`
  - backend / provider 設定
  - `stage/common` / `stage/dev` の定数 module 参照
  - `modules/network` 呼び出し
- `outputs.tf`
  - VPC ID
  - subnet ID
  - security group ID
  - target group ARN

## 外部公開する値

`network` stack は、後続の stack が参照するネットワーク情報を `outputs.tf` から公開する。

主な公開値:

- `vpc_id`
- `public_subnet_ids`
- `private_db_subnet_ids`
- `alb_security_group_id`
- `app_security_group_id`
- `db_security_group_id`
- `redis_security_group_id`
- `app_target_group_arn`
