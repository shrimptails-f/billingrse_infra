# Terraform アーキテクチャ設計

## 全体方針

このリポジトリでは、Terraformをstack単位で分離し、`stage/`配下の各ディレクトリをapplyの単位として扱います。
共通値はstack間で重複定義せず、小さな定数moduleとして切り出します。

### 設計意図

この構成は、責務ごとにリソースを分けて管理しつつ、必要な単位でapplyや削除を行いやすくすることを目的としています。
特にコスト削減のために一部リソースを削除したい場合に、コストの低いネットワーク関連リソースは残しつつ、アプリケーション関連リソースを削除しやすい構成にしています。
その方針に合わせて、他のディレクトリも同程度の粒度で分割しています。

## ディレクトリ構成

```text
stage/
├── common/ リポジトリ共通の定数module
│   ├── const.tf app_nameとaws_regionを管理
│   └── outputs.tf 他stack参照用の値を出力
├── dev/ dev環境の定数moduleとstack群
│   ├── const.tf dev環境固有の定数を管理
│   ├── outputs.tf 他stack参照用の値を出力
│   ├── state_manage/ remote state基盤を作る
│   ├── account/ OIDCやIAMロールなどを作る
│   ├── network/ VPCやsubnetなどネットワークを作る
│   └── application/ アプリ本体のインフラを作る
└── shared/ 環境横断で扱う
    └── domain/ ドメインや証明書関連を管理する
```

### 補足

- `stage/common`と`stage/dev`はリソースを直接作るstackではなく、他stackから参照される定数moduleとして扱う
- `stage/dev/state_manage`はremote state運用を成立させるためのbootstrap用ディレクトリとして扱う

## 共通値の参照について

値の依存関係は以下の通りです。

1. リポジトリ共通の値として、アプリ名やリージョンなどの定数を管理する
2. stageごとの値として、その環境で共通の定数を管理する
3. 各stackがそれらを参照して、resource名やprovider設定を構成する
