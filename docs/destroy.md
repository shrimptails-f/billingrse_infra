# 削除手順（dev環境）

このドキュメントは、`dev` 環境のリソースを削除する手順です。  
初回構築は [deployment.md](./deployment.md)、通常更新は [operations_deploy.md](./operations_deploy.md) を参照してください。

## 重要

- 削除は復旧不能な影響を与える可能性があります。
- 実行前に「何を残し、何を削除するか」を明確にしてください。
- `state_manage` 系は state 基盤のため、通常は削除しません。

## 削除の基本順序

依存関係の逆順で削除します。

1. `stage/dev/application`
2. （必要時のみ）`stage/dev/account`
3. （必要時のみ）`stage/dev/network`
4. （必要時のみ）`stage/shared/domain`
5. （通常は保持）`stage/dev/state_manage` / `stage/shared/state_manage`

通常運用では `application` のみ削除し、`account` / `network` は保持します。  
`account` / `network` は比較的低コストのため、毎回削除しない方針です。

## 事前確認

- 実行ディレクトリが `/home/dev/infra` であること
- GitHub Actions で実行中タスクがないこと
- DBデータ退避が必要なら先にバックアップすること

## 手順

### 1. application を削除

```bash
terraform -chdir=/home/dev/infra/stage/dev/application init
terraform -chdir=/home/dev/infra/stage/dev/application destroy
```

### 2. network を削除（必要時のみ）

```bash
terraform -chdir=/home/dev/infra/stage/dev/network init
terraform -chdir=/home/dev/infra/stage/dev/network destroy
```

### 3. account を削除（必要時のみ）

```bash
terraform -chdir=/home/dev/infra/stage/dev/account init
terraform -chdir=/home/dev/infra/stage/dev/account destroy
```

### 4. domain を削除（必要時のみ）

```bash
terraform -chdir=/home/dev/infra/stage/shared/domain init
terraform -chdir=/home/dev/infra/stage/shared/domain destroy
```

## RDS final snapshot について

`stage/dev/application` の設計上、通常削除では final snapshot を取得しません。  
データ退避が必要な場合のみ、`final_snapshot_identifier` に一意な値を設定して destroy してください。

例:

- `dev-db-final-20260420-01`

## state_manage を削除したい場合（非推奨）

`state_manage` には保護設定があります。

- S3 bucket: `prevent_destroy = true`
- DynamoDB lock table: `deletion_protection_enabled = true`

そのため、そのままでは destroy できません。  
削除が必要な場合のみ、対象設定を一時的に解除して apply 後に destroy してください。

対象:

- `/home/dev/infra/stage/dev/state_manage/main.tf`
- `/home/dev/infra/stage/shared/state_manage/main.tf`

## 削除後チェック

- ECS service / RDS / ALB / CloudFront が消えていること
- Route53 record の残骸がないこと
- 不要なECRリポジトリ/イメージが残っていないこと
- 想定外課金が発生しないこと（Cost Explorerで確認）
