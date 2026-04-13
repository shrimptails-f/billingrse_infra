# Terraform コーディング規約

## 基本方針

- Terraformの記述ルールは、stackごとにばらつかせず統一する。
- 定数と外部入力を混在させない。
- 1つの `.tf` に責務を詰め込みすぎない。単一責任原則を遵守
- ファイル名、local名、resource名は役割が見て分かる名前にする。

## ファイル分割

- `main.tf`はstackの中心となるresourceやproviderを置く。
- 関連する設定は責務ごとに専用ファイルへ分ける。
- セキュリティ設定、監視設定、ログ設定などは必要に応じて分離する。
- `variables.tf`と`outputs.tf`は分離する。
- 特定のサービスに依存する設定は、用途が分かるファイル名へ分離する。

## 命名規則

### ファイル

- 用途が分かるファイル名にする。
- リソース種別を示したい場合は接頭辞に入れる。
- 汎用的すぎる名前は避ける。

例:

- `main.tf`
- `s3_security.tf`
- `s3_logging.tf`
- `variables.tf`
- `outputs.tf`

### local

- local名は用途が分かる名前にする。
- 値の意味が曖昧な短い名前は避ける。

例:

- `state_bucket_name`
- `lock_table_name`
- `all_buckets`

### resource

- Terraformの論理名はAWS上の役割と対応する名前にする。
- 同じ種類のresourceが複数ある場合は用途で区別する。

例:

- `aws_s3_bucket.tfstate`
- `aws_s3_bucket.tfstate_logs`
- `aws_dynamodb_table.tfstate_lock`

### output

- 出力値は`name`や`arn`など、返す値の種類が分かる接尾辞を使う。

例:

- `state_bucket_name`
- `state_bucket_arn`
- `state_lock_table_name`
- `state_lock_table_arn`

## 定数について

- stageをまたぐリポジトリ共通の定数は`stage/common`を使う。
- `stage/dev`のような環境ディレクトリ配下では、その環境で共通の定数を使う。
- 定数は`locals`で管理する。
- 他ディレクトリから参照する定数は`outputs.tf`で出力する。
- stack側では`module`経由で参照する。

例:

```hcl
module "common" {
  source = "../../common"
}

module "dev" {
  source = "../"
}

locals {
  sample_name = "${module.common.app_name}-${module.dev.stage}"
}
```

## variablesの扱い

- `variables.tf`には外部から受け取る入力だけを定義する。
- 定数値の`default`は極力置かない。
- 共通化できる値は`variables.tf`に重複定義しない。
- 変数名は省略せず、用途が分かる名前にする。

## outputsの扱い

- `outputs.tf`には外部から参照させる値だけを定義する。
- 内部でしか使わない値は`output`にしない。
- output名は何を返すか分かる名前にする。

例:

- `state_bucket_name`
- `state_lock_table_name`
