# 運用時デプロイ手順（dev環境）

このドキュメントは、初回構築後の通常運用で実施するデプロイ手順をまとめたものです。  
初回構築は [deployment.md](./deployment.md) を参照してください。

## 前提

- `stage/dev/application` が apply 済みであること
- GitHub Actions の `AWS_ROLE_ARN` など必要な Secrets が設定済みであること
- `dev` 環境の domain / certificate が有効であること

## 更新パターン

### 1. バックエンドのみ更新（コード変更のみ）

1. [Backend Actions](https://github.com/shrimptails-f/billingrse_backend/actions) で `Deploy Backend` を実行
2. `image_tag` は未指定（SHA自動）または任意タグを指定
3. 実行完了後、ECS service が stable になることを確認

補足:
- `Deploy Backend` ワークフロー内で test -> ECR push -> ECS deploy まで実行されます。

### 2. DBスキーマ変更あり（migrationが必要）

1. [Backend Actions](https://github.com/shrimptails-f/billingrse_backend/actions) で `Run DB Migration Task` を実行
2. 必要な場合のみ `Run DB Seed` を実行
3. [Backend Actions](https://github.com/shrimptails-f/billingrse_backend/actions) で `Deploy Backend` を実行

補足:
- migration と backend の順序は変更内容に依存します。  
  非互換変更を含む場合は、必ずメンテナンス方針と合わせて判断してください。

### 3. フロントエンドのみ更新

1. [Frontend Actions](https://github.com/shrimptails-f/billingrse_front/actions) で `Deploy Frontend to S3` を実行
2. CloudFront の配信更新を確認

### 4. Redis / DB init イメージ更新（infra側運用）

1. [Infra Actions](https://github.com/shrimptails-f/billingrse_infra/actions) で `Push Redis Image` または `Push DB Init Image` を実行
2. DB初期化が必要なときのみ `Run DB Init` を実行

## Terraform変更を含む運用デプロイ

Terraformの変更がある場合は、依存順で対象 stack のみ apply します。
通常運用では `application` のみ apply し、`account` / `network` は変更がある場合のみ apply します。

推奨順序:

1. `stage/dev/account`（変更時のみ）
2. `stage/dev/network`（変更時のみ）
3. `stage/shared/domain`（必要時）
4. `stage/dev/application`

実行例:

```bash
terraform -chdir=/home/dev/infra/stage/dev/application init
terraform -chdir=/home/dev/infra/stage/dev/application apply
```

## 動作確認チェック

- backend: ALB経由でヘルスチェックが `healthy`
- frontend: CloudFront経由で最新UIが表示される
- migration実行時: エラーなくtaskが終了する
- アプリログ: CloudWatch Logs にエラー急増がない

## ロールバック方針

- backend: 直前の安定 `image_tag` を指定して `Deploy Backend` を再実行
- frontend: 直前の安定コミットを再デプロイ
- DB: migrationのロールバック可否は変更内容に依存（必要時は手動対応）
