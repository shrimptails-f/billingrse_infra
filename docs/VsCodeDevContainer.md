# 環境構築手順

## 1.ソースをクローン

```bash
git clone git@github.com:shrimptails-f/billingrse_infra.git
```

## 2. VsCodeでプロジェクトフォルダーを開く

## 3. Reopen in Containerを押下

もし表示されない場合は Ctrl Shift P→Reopen in containerと入力して実行でもおｋ

## 4. AWSコマンドにアクセスキーを登録
```bash
aws configure
```
アクセスキーとシークレットキーを入力。  
リージョンはap-northeast-1を指定する。

## 5. account stack 用の環境変数を設定

```bash
cp .devcontainer/.env.sample .devcontainer/.env
```

```env
TF_VAR_dev_aws_account_id= 利用する AWS アカウント ID（12桁）を設定してください。
下記は将来用の予約項目です（`stage/dev` では未使用）
TF_VAR_stg_aws_account_id
TF_VAR_prd_aws_account_id
```

# 環境構築完了です！！

お疲れ様でした。
