# デプロイ手順（dev環境）
## 前提
- [ローカル環境構築](./VsCodeDevContainer.md)が完了していること
- ドメインをレンタル済みであること
   AWS以外でレンタルした場合、AWSのRoute53のDNS名の登録が必要になるので各自で調べて設定してください。

## 事前準備

## openai APIキーを発行
1. https://openai.com/ja-JP/api/ にアクセスしてアカウント登録
2. https://platform.openai.com/api-keys にアクセスしてAPIキーを発行
3. 発行したAPIキーを控えておく

### 注意事項
- OpenAI APIの利用には料金が発生します
- APIキーは安全に管理してください

## Google OAuth2設定
1. [Google Cloud Console](https://console.cloud.google.com/)にアクセス
2. https://console.developers.google.com/apis/library にアクセスし、「Gmail API」で検索→Gmail-apiを有効化する。
4. https://console.cloud.google.com/apis/credentials にアクセスし、認証情報を作成→OAuthクライアントIDを選択する。
5. アプリケーションの種類として「ウェブアプリケーション」を選択
6. 承認済みのリダイレクトURIに `https://dev.shrimptail.net/mail-account-connections/gmail/callback` を追加
7. 秘密鍵をJSONでダウンロード あとで使います。

### AWS Secrets Managerにリソース作成
AWS Secrets Managerに`billingrse_dev`という名前で作成し、下記の**必須項目**を定義してください。
```text
JWT_SECRET_KEY=<JWT署名に使う十分長いランダム文字列>
OPENAI_API_KEY=<OpenAIで発行したAPIキー>
EMAIL_TOKEN_KEY_V1=<メールトークン暗号化に使う32文字以上の鍵>
EMAIL_TOKEN_SALT=<メールトークン用のランダムなソルト値>
REDIS_PASSWORD=<Redis接続パスワード>
EMAIL_GMAIL_CLIENT_ID=<Google OAuth2クライアントID>
EMAIL_GMAIL_CLIENT_SECRET=<Google OAuth2クライアントシークレット>
```

補足:
- `MYSQL_USER` / `MYSQL_PASSWORD` は `billingrse_dev` に入れません。RDS作成時に生成される Secrets Manager の値を参照します。
- `DB_HOST` / `DB_PORT` も `billingrse_dev` に入れません。インフラ側で解決してアプリ環境変数へ注入します。

## リソース作成

### 前提
実行場所確認
```
pwd

/home/dev/infraと表示されること。
```

### 各種デプロイ実行
1. `stage/shared/state_manage`をapplyする
```
terraform -chdir=/home/dev/infra/stage/shared/state_manage init
terraform -chdir=/home/dev/infra/stage/shared/state_manage apply
```
2. `stage/dev/state_manage`をapplyする
```
terraform -chdir=/home/dev/infra/stage/dev/state_manage init
terraform -chdir=/home/dev/infra/stage/dev/state_manage apply
```
3. `stage/shared/domain`をapplyする  
```
terraform -chdir=/home/dev/infra/stage/shared/domain init
terraform -chdir=/home/dev/infra/stage/shared/domain apply
```
4. `stage/dev/network`をapplyする
```
terraform -chdir=/home/dev/infra/stage/dev/network init
terraform -chdir=/home/dev/infra/stage/dev/network apply
```
5. `stage/dev/account`をapplyする
```
terraform -chdir=/home/dev/infra/stage/dev/account init
terraform -chdir=/home/dev/infra/stage/dev/account apply
```
6. [Infra](https://github.com/shrimptails-f/billingrse_infra/actions)のリポジトリのActionsタブから`Push DB Init Image`を実行  
   イメージタグにはお好きな値を指定してください。  
   ※後で同じ値を入力するのでわかりやすい値がおすすめです。
7. [Infra](https://github.com/shrimptails-f/billingrse_infra/actions)のリポジトリのActionsタブから`Push Redis Image`を実行  
   イメージタグにはお好きな値を指定してください。  
   ※後で同じ値を入力するのでわかりやすい値がおすすめです。
8. `stage/dev/application`をapplyする
```
terraform -chdir=/home/dev/infra/stage/dev/application init
terraform -chdir=/home/dev/infra/stage/dev/application apply
```
9. [Infra](https://github.com/shrimptails-f/billingrse_infra/actions)のリポジトリのActionsタブから`Run DB Init`を実行  
   イメージタグには、`Push DB Init Image`を実行した際の値を入力してください。  
10. [Backend](https://github.com/shrimptails-f/billingrse_backend/actions)のリポジトリのActionsタブから`Run DB Migration Task`を実行  
   イメージタグにはお好きな値を指定してください。
11. [Backend](https://github.com/shrimptails-f/billingrse_backend/actions)のリポジトリのActionsタブから`Run DB Seed`を実行  
   イメージタグにはお好きな値を指定してください。  
12. [Backend](https://github.com/shrimptails-f/billingrse_backend/actions)のリポジトリのActionsタブから`Deploy Backend`を実行  
    イメージタグは空欄で実行可能です（未指定時はコミットSHAが使用されます）。
13. [Frontend](https://github.com/shrimptails-f/billingrse_front/actions)のリポジトリのActionsタブから`Deploy Frontend to S3`を実行  
