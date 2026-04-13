# デプロイ手順（dev環境）

terraform applyコマンド実行は以後applyと表記します。

## 事前準備

1. `stage/shared/state_manage`でapplyする
2. domainを購入orレンタルする
3. Route53に登録する
   `stage/shared/domain`でapplyする  
   https://aws.amazon.com/jp/getting-started/hands-on/get-a-domain/
4. AWS SecretManagerにbillingrse_devを作成し、下記を定義する。

```text
JWT_SECRET_KEY
OPENAI_API_KEY
EMAIL_TOKEN_KEY_V1
EMAIL_TOKEN_SALT
REDIS_PASSWORD
MYSQL_USER
MYSQL_PASSWORD
DB_HOST
DB_PORT
EMAIL_GMAIL_CLIENT_ID
EMAIL_GMAIL_CLIENT_SECRET
```

## リソース作成

1. `stage/dev/state_manage`でapplyする
2. `stage/dev/account`でapplyする
3. `stage/dev/network`でapplyする
4. GitHubのActionsタブから`Push DB Init Image to ECR`を実行
5. BackendのリポジトリのActionsタブから`Push Image to ECR`を実行
6. BackendのリポジトリのActionsタブから`Push DB Migration Image to ECR`を実行
7. `stage/dev/application`でapplyする
8. GitHubのActionsタブから`Run DB Init Task`を実行
9. BackendのリポジトリのActionsタブから`Run DB Migration Task`を実行
10. BackendのリポジトリのActionsタブから`Run DB Seeder Task`を実行
11. FrontのリポジトリのActionsタブから`Deploy Frontend to S3`を実行
