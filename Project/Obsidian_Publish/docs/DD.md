# Obsidian Publish風 Quartz SSG 実装設計書

## 1. 前提条件・環境

- **ベースシステム:** Quartz v4
- **パッケージマネージャ:** npm
- **対象コンテンツ:** Obsidian Vault内のMarkdownファイル（Quartzの `content` フォルダに配置）
- **ホスティング:** AWS Amplify (GitHub Actions経由で自動デプロイ)

## 2. 画面レイアウト設計 (`quartz.layout.ts`)

Obsidian Publishの3カラムレイアウトを完全に再現するため、コンポーネントを以下のように配置すること。

### A. 共通設定 (sharedPageComponents)

- `head`: `Component.Head()`
- `header`: 空配列 `[]`
- `afterBody`: 空配列 `[]`
- `footer`: `Component.Footer()`

### B. 記事ページレイアウト (defaultContentPageLayout)

**左サイドバー (beforeBody / Desktop: 左, Mobile: 上部)**

- `Component.PageTitle()`: サイト名（ロゴ感覚）
- `Component.MobileOnly(Component.Spacer())`: モバイル用余白
- `Component.Search()`: サイト内検索（必須）
- `Component.Darkmode()`: ダークモード切替トグル
- `Component.DesktopOnly(Component.Explorer({ title: "Explorer" }))`: フォルダツリー（PCのみ表示）

**メインコンテンツ (ヘッダー部分)**

- `Component.ArticleTitle()`: ノートのH1タイトル
- `Component.ContentMeta()`: 読了時間・更新日など
- `Component.TagList()`: タグ一覧

**右サイドバー (right / Desktop: 右, Mobile: 下部)**

- `Component.Graph({ localGraph: { depth: 1 }, globalGraph: { depth: 2 } })`: グラフビュー（Obsidianの醍醐味）
- `Component.DesktopOnly(Component.TableOfContents())`: 目次 (PCのみ)
- `Component.Backlinks()`: バックリンク（このノートへのリンク元一覧）

## 3. テーマ・プラグイン設計 (`quartz.config.ts`)

### A. タイポグラフィとデザイン (theme)

- **フォント:** \* `header`: `"Schibsted Grotesk", "Noto Sans JP", sans-serif`
  - `body`: `"Source Sans Pro", "Noto Sans JP", sans-serif`
  - `code`: `"Fira Code", monospace`
- **カラーパレット (Obsidian Publish風):**
  - `primary`: `#7c3aed` (Obsidian公式っぽいパープル系アクセント)
  - `secondary`: `#4c1d95` (リンク色など)
  - `lightMode`: 白背景（`#ffffff` または `#fcfcfc`）にダークグレーの文字
  - `darkMode`: 黒背景（`#1e1e20`）にライトグレーの文字（`#ebebec`）を指定し、コントラストを和らげる

### B. プラグイン (plugins)

Obsidianの独自記法を解釈するため、以下のプラグインを有効化すること。

- **Transformers (Markdownの解釈):**
  - `Plugin.FrontMatter()`
  - `Plugin.CreatedModifiedDate({ priority: ["frontmatter", "filesystem"] })`
  - `Plugin.SyntaxHighlighting()`
  - `Plugin.ObsidianFlavoredMarkdown({ enableInHtmlEmbed: false })`: コールアウト(`> [!note]`)やWikilink(`[[link]]`)を解釈
  - `Plugin.GitHubFlavoredMarkdown()`
  - `Plugin.TableOfContents()`
  - `Plugin.CrawlLinks({ markdownLinkResolution: "shortest" })`: リンク解決をObsidianの挙動に合わせる
- **Filters (出力制御):**
  - `Plugin.RemoveDrafts()`: プロパティ(frontmatter)に `draft: true` があるものを非公開にする

## 4. 運用・デプロイ要件

- **コンテンツ同期:** ObsidianのVault内の公開したいフォルダと、Quartzの `content/` ディレクトリを同期・配置する。
- **GitHub Actions構築:** `.github/workflows/deploy.yml` を作成し、`main` ブランチにPushされたら `npx quartz build` を実行してAWS Amplifyへ自動デプロイするCI/CDを組むこと。

### デプロイフロー

```
main ブランチへ Push
  └─ GitHub Actions 起動
       ├─ npm ci
       ├─ npx quartz build → public/ を生成
       ├─ public/ を zip 圧縮 → S3 へアップロード
       └─ aws amplify start-deployment → Amplify がS3から取得してホスティング
```

### 必要なAWSリソース

| リソース | 用途 |
|---|---|
| S3バケット | ビルド成果物の中間置き場 |
| Amplify App | 静的サイトのホスティング |
| IAMユーザー | GitHub ActionsからAWSを操作するための認証情報 |

### GitHub Secrets 設定値

| Secret名 | 説明 |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAMユーザーのアクセスキー |
| `AWS_SECRET_ACCESS_KEY` | IAMユーザーのシークレットキー |
| `AWS_REGION` | AWSリージョン（例: `ap-northeast-1`） |
| `S3_BUCKET` | 中間ファイル置き場のS3バケット名 |
| `AMPLIFY_APP_ID` | AmplifyコンソールのApp ID |
