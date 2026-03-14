# Obsidian Publish 風 静的サイト

ObsidianのVaultをQuartz v4でビルドし、AWS Amplifyで公開するシステムです。
`main`ブランチにPushするだけで自動でサイトが更新されます。

---

## システム全体像

```mermaid
flowchart TD
    A[👤 あなた\nObsidianでノートを書く] --> B[GitHubリポジトリ\nmainブランチにPush]

    B --> C{GitHub Actions\ndeploy.yml}

    C --> D[① npm ci\n依存パッケージをインストール]
    D --> E[② npx quartz build\nMarkdown → 静的HTML に変換]
    E --> F[③ public/ を\ndeploy.zip に圧縮]
    F --> G[④ S3バケットに\ndeploy.zip をアップロード]
    G --> H[⑤ aws amplify start-deployment\nS3のzipを指定してデプロイ命令]

    H --> I[AWS Amplify\nS3からzipを取得してホスティング反映]

    I --> J[🌐 サイト公開\nyour-domain.amplifyapp.com]

    K[👤 読者] --> J
```

---

## デプロイの詳細フロー

```mermaid
sequenceDiagram
    actor You as あなた
    participant GH as GitHub
    participant GA as GitHub Actions
    participant S3 as AWS S3
    participant Amp as AWS Amplify

    You->>GH: git push origin main
    GH->>GA: Pushイベント検知 → ワークフロー起動

    GA->>GA: npm ci（依存インストール）
    GA->>GA: npx quartz build（HTML生成 → public/）
    GA->>GA: zip -r deploy.zip public/

    GA->>S3: deploy.zip をアップロード
    S3-->>GA: アップロード完了

    GA->>Amp: start-deployment（S3のURLを指定）
    Amp->>S3: deploy.zip をダウンロード
    S3-->>Amp: zip取得完了
    Amp->>Amp: 展開・ホスティング反映

    Amp-->>You: デプロイ完了 🎉
```

---

## ページレイアウト（Obsidian Publish風 3カラム）

```
┌─────────────────────────────────────────────────────────────┐
│                         ページ全体                           │
├──────────────┬──────────────────────────┬───────────────────┤
│  左サイドバー │      メインコンテンツ      │  右サイドバー      │
│              │                          │                   │
│ サイト名      │ # 記事タイトル            │ グラフビュー        │
│ 検索          │ 更新日 / 読了時間 / タグ   │ (ノード間の繋がり)  │
│ ダークモード  │                          │                   │
│              │ 本文...                  │ 目次 (PC のみ)     │
│ Explorerツリー│                          │                   │
│ (PC のみ)    │                          │ バックリンク        │
│              │                          │                   │
└──────────────┴──────────────────────────┴───────────────────┘
```

| エリア | コンポーネント |
|---|---|
| 左サイドバー | PageTitle, Search, Darkmode, Explorer（PC限定） |
| メイン上部 | ArticleTitle, ContentMeta, TagList |
| 右サイドバー | Graph, TableOfContents（PC限定）, Backlinks |

---

## AWSインフラ構成

```mermaid
graph LR
    subgraph GitHub
        Repo[リポジトリ]
        GA[GitHub Actions]
    end

    subgraph AWS
        S3[S3バケット\n成果物の中間置き場\n7日で自動削除]
        Amp[AWS Amplify\n静的サイトホスティング]
    end

    GA -- deploy.zip をアップロード --> S3
    GA -- start-deployment 命令 --> Amp
    Amp -- zip をダウンロード --> S3
    Amp -- 配信 --> Web[🌐 インターネット]
```

### Terraformで管理しているリソース

| リソース | 内容 |
|---|---|
| `aws_amplify_app` | Amplifyアプリ本体（ビルド機能はOFF） |
| `aws_amplify_branch` | mainブランチ（auto_build無効） |
| `aws_s3_bucket` | デプロイ成果物の中間置き場 |
| `aws_s3_bucket_public_access_block` | バケットへのパブリックアクセスを完全ブロック |
| `aws_s3_bucket_lifecycle_configuration` | 7日経過したzipを自動削除 |

---

## Quartzのコンテンツ処理パイプライン

```mermaid
flowchart LR
    A[Obsidian Vault\n.md ファイル群] --> B

    subgraph Quartz[npx quartz build]
        B[Transformers\nMarkdownを解析] --> C[Filters\n非公開ノートを除外]
        C --> D[Emitters\nHTML / CSS / JS を生成]
    end

    D --> E[public/\n静的ファイル一式]

    subgraph Transformers詳細
        T1["FrontMatter\n--- タグを解析"]
        T2["ObsidianFlavoredMarkdown\n[[Wikilink]] / Callout対応"]
        T3["CrawlLinks\nリンク解決をObsidian準拠に"]
        T4["SyntaxHighlighting\nコードブロックに色付け"]
    end

    subgraph Filters詳細
        F1["RemoveDrafts\ndraft: true のノートを除外"]
    end
```

---

## ディレクトリ構成

```
Obsidian_Publish/
├── quartz.config.ts          # テーマ・プラグイン設定
├── quartz.layout.ts          # 3カラムレイアウト設定
├── content/                  # Obsidian Vaultのmdファイルをここに配置
│
├── .github/
│   └── workflows/
│       └── deploy.yml        # CI/CD（Push → ビルド → Amplifyデプロイ）
│
├── modules/
│   ├── Amplify/              # Amplify Terraformモジュール
│   │   ├── amplify.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── S3/                   # S3 Terraformモジュール
│       ├── s3.tf
│       ├── variables.tf
│       └── outputs.tf
│
├── environments/
│   └── dev/                  # dev環境の設定
│       ├── main.tf
│       ├── provider.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── terraform.tfvars  # ← 自分の環境に合わせて編集
│
└── docs/
    └── DD.md                 # 設計書
```

---

## セットアップ手順

### 1. AWSインフラを作成（Terraform）

```bash
cd environments/dev
terraform init
terraform apply
# → amplify_app_id と s3_bucket_name が出力される
```

### 2. GitHub Secretsを登録

リポジトリの **Settings → Secrets and variables → Actions** に以下を追加：

| Secret名 | 説明 |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAMユーザーのアクセスキー |
| `AWS_SECRET_ACCESS_KEY` | IAMユーザーのシークレットキー |
| `AWS_REGION` | `ap-northeast-1` |
| `S3_BUCKET` | `terraform apply`の出力値 |
| `AMPLIFY_APP_ID` | `terraform apply`の出力値 |

### 3. コンテンツを配置してPush

```bash
# ObsidianのVaultをcontentフォルダに配置
cp -r /path/to/your/vault/* content/

git add .
git commit -m "ノートを追加"
git push origin main
# → GitHub Actionsが自動でビルド＆デプロイ
```

---

## ノートの公開・非公開制御

frontmatterで制御できます：

```yaml
---
# 公開したくないノートはこれを追加
draft: true
---
```

`draft: true` がついたノートはビルド時に自動的に除外されます。
