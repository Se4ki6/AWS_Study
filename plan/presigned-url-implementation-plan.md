# S3 画像ファイル署名付き URL 実装プラン

最終更新: 2025-11-29

## 概要

S3 バケット内の画像ファイルに対して、セキュアな署名付き URL（Presigned URL）を発行できるようにする実装プランです。
段階的にオプション 1（署名付き URL）を導入し、将来的には CloudFront とのハイブリッド構成に移行します。

## アーキテクチャ概要

```
┌─────────────┐
│   クライアント  │
└──────┬──────┘
       │ ① URLリクエスト
       ▼
┌─────────────────────┐
│ URL生成スクリプト/API  │
│   (Python/Lambda)   │
└──────┬──────────────┘
       │ ② S3署名付きURL生成
       │    (IAMロール経由)
       ▼
┌─────────────┐
│   S3バケット   │
│  (プライベート) │
└─────────────┘
       │ ③ 一時的なアクセス
       │    (期限付きURL)
       ▼
┌─────────────┐
│   クライアント  │
└─────────────┘
```

## 実装ステップ

### ステップ 1: 署名付き URL 生成用の IAM ポリシー追加

#### 目的

S3 オブジェクトへの`GetObject`権限を持つ IAM ユーザー/ロールを作成し、署名付き URL の生成を可能にします。

#### 実装内容

##### 1.1 IAM ポリシーの作成

**ファイル**: `S3/iam.tf`（新規作成）

```hcl
# S3署名付きURL生成用のIAMポリシー
resource "aws_iam_policy" "s3_presigned_url_generator" {
  name        = "${var.bucket_name}-presigned-url-generator"
  description = "S3バケットのオブジェクトに対する署名付きURL生成用ポリシー"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3GetObject"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.example.arn,
          "${aws_s3_bucket.example.arn}/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "${var.bucket_name}-presigned-url-generator"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
```

##### 1.2 IAM ユーザーの作成（ローカル開発用）

```hcl
# S3署名付きURL生成用のIAMユーザー（ローカル開発用）
resource "aws_iam_user" "s3_presigned_url_user" {
  count = var.create_iam_user ? 1 : 0
  name  = "${var.bucket_name}-presigned-url-user"

  tags = {
    Name        = "${var.bucket_name}-presigned-url-user"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ポリシーをユーザーにアタッチ
resource "aws_iam_user_policy_attachment" "s3_presigned_url_user_policy" {
  count      = var.create_iam_user ? 1 : 0
  user       = aws_iam_user.s3_presigned_url_user[0].name
  policy_arn = aws_iam_policy.s3_presigned_url_generator.arn
}

# アクセスキーの作成
resource "aws_iam_access_key" "s3_presigned_url_user_key" {
  count = var.create_iam_user ? 1 : 0
  user  = aws_iam_user.s3_presigned_url_user[0].name
}
```

##### 1.3 IAM ロールの作成（Lambda/EC2 用）

```hcl
# Lambda/EC2用のIAMロール
resource "aws_iam_role" "s3_presigned_url_role" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.bucket_name}-presigned-url-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = var.iam_role_service # "lambda.amazonaws.com" or "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.bucket_name}-presigned-url-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ポリシーをロールにアタッチ
resource "aws_iam_role_policy_attachment" "s3_presigned_url_role_policy" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.s3_presigned_url_role[0].name
  policy_arn = aws_iam_policy.s3_presigned_url_generator.arn
}
```

##### 1.4 variables.tf への追加

```hcl
# IAMユーザーを作成するかどうか（ローカル開発用）
variable "create_iam_user" {
  description = "IAMユーザーを作成するかどうか（ローカル開発用）"
  type        = bool
  default     = true
}

# IAMロールを作成するかどうか（Lambda/EC2用）
variable "create_iam_role" {
  description = "IAMロールを作成するかどうか（Lambda/EC2用）"
  type        = bool
  default     = false
}

# IAMロールのサービスプリンシパル
variable "iam_role_service" {
  description = "IAMロールの使用サービス（lambda.amazonaws.com or ec2.amazonaws.com）"
  type        = string
  default     = "lambda.amazonaws.com"
}
```

##### 1.5 outputs.tf への追加

```hcl
# IAMユーザーの情報を出力
output "iam_user_name" {
  description = "IAMユーザー名"
  value       = var.create_iam_user ? aws_iam_user.s3_presigned_url_user[0].name : null
}

output "iam_user_arn" {
  description = "IAMユーザーARN"
  value       = var.create_iam_user ? aws_iam_user.s3_presigned_url_user[0].arn : null
}

output "iam_access_key_id" {
  description = "IAMアクセスキーID"
  value       = var.create_iam_user ? aws_iam_access_key.s3_presigned_url_user_key[0].id : null
  sensitive   = true
}

output "iam_secret_access_key" {
  description = "IAMシークレットアクセスキー"
  value       = var.create_iam_user ? aws_iam_access_key.s3_presigned_url_user_key[0].secret : null
  sensitive   = true
}

# IAMロールの情報を出力
output "iam_role_name" {
  description = "IAMロール名"
  value       = var.create_iam_role ? aws_iam_role.s3_presigned_url_role[0].name : null
}

output "iam_role_arn" {
  description = "IAMロールARN"
  value       = var.create_iam_role ? aws_iam_role.s3_presigned_url_role[0].arn : null
}
```

#### セキュリティ考慮事項

- **アクセスキーの管理**: `terraform output`で取得した認証情報は安全に保管
- **最小権限の原則**: `GetObject`と`ListBucket`のみを許可
- **バケット固有**: 特定の S3 バケットのみに権限を限定
- **ローテーション**: 定期的なアクセスキーのローテーションを推奨

---

### ステップ 2: 画像専用プレフィックスの設定

#### 目的

画像ファイルを`images/`配下に配置し、整理されたバケット構造を実現します。

#### 実装内容

##### 2.1 variables.tf への追加

```hcl
# 画像ファイル専用のS3プレフィックス
variable "images_prefix" {
  description = "画像ファイルをアップロードするS3プレフィックス（フォルダパス）"
  type        = string
  default     = "images"
}

# 画像ファイルが格納されているローカルフォルダ
variable "images_upload_folder" {
  description = "画像ファイルが格納されているローカルフォルダのパス"
  type        = string
  default     = "upload_file/images"
}
```

##### 2.2 main.tf への画像アップロード設定追加

```hcl
# 画像ファイル専用のアップロード設定
resource "aws_s3_object" "upload_images" {
  # 画像フォルダ内の全ファイルを取得
  for_each = fileset(var.images_upload_folder, "**")

  bucket = aws_s3_bucket.example.id

  # images/配下に配置
  key = "${var.images_prefix}/${each.value}"

  source = "${var.images_upload_folder}/${each.value}"

  etag = filemd5("${var.images_upload_folder}/${each.value}")

  # 画像のContent-Type設定
  content_type = lookup({
    "png"  = "image/png",
    "jpg"  = "image/jpeg",
    "jpeg" = "image/jpeg",
    "gif"  = "image/gif",
    "svg"  = "image/svg+xml",
    "webp" = "image/webp",
    "ico"  = "image/x-icon",
    "bmp"  = "image/bmp",
    "tiff" = "image/tiff",
    "tif"  = "image/tiff"
  }, lower(split(".", each.value)[length(split(".", each.value)) - 1]), "application/octet-stream")

  # 画像は長期キャッシュ（1年）
  cache_control = "max-age=31536000, immutable"
}
```

##### 2.3 ディレクトリ構造

```
S3/
├── upload_file/
│   ├── index.html
│   ├── error.html
│   └── images/          # 新規作成
│       ├── logo.png
│       ├── banner.jpg
│       └── icon.svg
```

##### 2.4 outputs.tf への追加

```hcl
# 画像用のベースパス
output "images_base_path" {
  description = "S3内の画像ファイルのベースパス"
  value       = var.images_prefix
}

# アップロードされた画像ファイルのリスト
output "uploaded_images" {
  description = "アップロードされた画像ファイルのキー一覧"
  value       = [for obj in aws_s3_object.upload_images : obj.key]
}
```

#### フォルダ構成のベストプラクティス

```
s3://your-bucket/
├── images/              # 画像専用
│   ├── products/
│   ├── users/
│   └── common/
├── documents/           # ドキュメント
└── assets/             # その他静的ファイル
```

---

### ステップ 3: URL 生成スクリプトの作成

#### 目的

Python (boto3) を使用して署名付き URL を生成するスクリプトを作成します。

#### 実装内容

##### 3.1 ディレクトリ構造

```
S3/
├── scripts/                    # 新規作成
│   ├── generate_presigned_url.py
│   ├── requirements.txt
│   └── .env.example
```

##### 3.2 requirements.txt

```text
boto3>=1.28.0
python-dotenv>=1.0.0
```

##### 3.3 .env.example

```bash
# AWS認証情報
AWS_ACCESS_KEY_ID=your_access_key_id
AWS_SECRET_ACCESS_KEY=your_secret_access_key
AWS_REGION=ap-southeast-2

# S3設定
S3_BUCKET_NAME=your-bucket-name
S3_IMAGES_PREFIX=images

# 署名付きURLの有効期限（秒）
PRESIGNED_URL_EXPIRATION=3600
```

##### 3.4 generate_presigned_url.py

```python
#!/usr/bin/env python3
"""
S3署名付きURL生成スクリプト

使用方法:
    python generate_presigned_url.py <image_filename>
    python generate_presigned_url.py logo.png
    python generate_presigned_url.py products/item-001.jpg

機能:
    - S3バケット内の画像ファイルに対して署名付きURLを生成
    - 有効期限付き（デフォルト: 1時間）
    - セキュアなプライベートアクセス
"""

import os
import sys
import boto3
from botocore.exceptions import ClientError, NoCredentialsError
from dotenv import load_dotenv
from datetime import datetime, timedelta

# 環境変数の読み込み
load_dotenv()

class PresignedURLGenerator:
    """S3署名付きURL生成クラス"""

    def __init__(self):
        """初期化とAWS認証情報の設定"""
        self.bucket_name = os.getenv('S3_BUCKET_NAME')
        self.images_prefix = os.getenv('S3_IMAGES_PREFIX', 'images')
        self.expiration = int(os.getenv('PRESIGNED_URL_EXPIRATION', 3600))

        # AWS認証情報の検証
        if not self.bucket_name:
            raise ValueError("S3_BUCKET_NAME が設定されていません")

        # S3クライアントの初期化
        try:
            self.s3_client = boto3.client(
                's3',
                aws_access_key_id=os.getenv('AWS_ACCESS_KEY_ID'),
                aws_secret_access_key=os.getenv('AWS_SECRET_ACCESS_KEY'),
                region_name=os.getenv('AWS_REGION', 'ap-southeast-2')
            )
        except NoCredentialsError:
            raise ValueError("AWS認証情報が設定されていません")

    def generate_presigned_url(self, object_key: str, expiration: int = None) -> dict:
        """
        署名付きURLを生成

        Args:
            object_key: S3オブジェクトのキー（例: "logo.png" or "products/item.jpg"）
            expiration: URL有効期限（秒）。Noneの場合はデフォルト値を使用

        Returns:
            dict: URLと有効期限情報を含む辞書
            {
                'url': '署名付きURL',
                'expires_at': '有効期限（ISO形式）',
                'expires_in_seconds': 有効期限（秒）
            }

        Raises:
            ClientError: S3へのアクセスエラー
        """
        if expiration is None:
            expiration = self.expiration

        # プレフィックスを含む完全なオブジェクトキーを構築
        full_key = f"{self.images_prefix}/{object_key}"

        try:
            # オブジェクトの存在確認
            self.s3_client.head_object(Bucket=self.bucket_name, Key=full_key)

            # 署名付きURL生成
            presigned_url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': self.bucket_name,
                    'Key': full_key
                },
                ExpiresIn=expiration
            )

            # 有効期限の計算
            expires_at = datetime.now() + timedelta(seconds=expiration)

            return {
                'url': presigned_url,
                'expires_at': expires_at.isoformat(),
                'expires_in_seconds': expiration,
                'object_key': full_key
            }

        except ClientError as e:
            error_code = e.response['Error']['Code']
            if error_code == '404':
                raise FileNotFoundError(f"オブジェクトが見つかりません: {full_key}")
            else:
                raise e

    def list_available_images(self) -> list:
        """
        利用可能な画像ファイルのリストを取得

        Returns:
            list: 画像ファイルのキー一覧
        """
        try:
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket_name,
                Prefix=f"{self.images_prefix}/"
            )

            if 'Contents' not in response:
                return []

            # プレフィックスを除いたファイル名のリスト
            images = [
                obj['Key'].replace(f"{self.images_prefix}/", "")
                for obj in response['Contents']
                if not obj['Key'].endswith('/')  # フォルダを除外
            ]

            return images

        except ClientError as e:
            print(f"エラー: 画像リストの取得に失敗しました - {e}")
            return []


def main():
    """メイン実行関数"""

    # コマンドライン引数のチェック
    if len(sys.argv) < 2:
        print("使用方法: python generate_presigned_url.py <image_filename>")
        print("\n例:")
        print("  python generate_presigned_url.py logo.png")
        print("  python generate_presigned_url.py products/item-001.jpg")
        print("\n利用可能な画像を表示するには: python generate_presigned_url.py --list")
        sys.exit(1)

    try:
        generator = PresignedURLGenerator()

        # 画像リスト表示モード
        if sys.argv[1] == '--list':
            print(f"\n利用可能な画像ファイル（バケット: {generator.bucket_name}）:")
            print("-" * 60)
            images = generator.list_available_images()
            if images:
                for img in images:
                    print(f"  {img}")
            else:
                print("  画像ファイルが見つかりません")
            print()
            return

        # 署名付きURL生成
        image_filename = sys.argv[1]
        result = generator.generate_presigned_url(image_filename)

        # 結果を表示
        print("\n" + "=" * 80)
        print("署名付きURL生成成功")
        print("=" * 80)
        print(f"オブジェクトキー: {result['object_key']}")
        print(f"有効期限: {result['expires_in_seconds']}秒 ({result['expires_in_seconds'] // 60}分)")
        print(f"期限切れ日時: {result['expires_at']}")
        print("\n署名付きURL:")
        print("-" * 80)
        print(result['url'])
        print("-" * 80)
        print("\nこのURLは上記の有効期限まで使用できます。")
        print("=" * 80 + "\n")

    except FileNotFoundError as e:
        print(f"\nエラー: {e}")
        print("\n利用可能な画像を確認するには:")
        print("  python generate_presigned_url.py --list\n")
        sys.exit(1)
    except ValueError as e:
        print(f"\n設定エラー: {e}")
        print("`.env` ファイルを確認してください。\n")
        sys.exit(1)
    except Exception as e:
        print(f"\n予期しないエラー: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
```

##### 3.5 セットアップ手順

**ステップ 3.1: 依存関係のインストール**

```bash
cd S3/scripts
pip install -r requirements.txt
```

**ステップ 3.2: 環境変数の設定**

```bash
# .env.exampleをコピー
cp .env.example .env

# .envファイルを編集（Terraformのoutputから取得）
# AWS_ACCESS_KEY_ID=<terraform output -raw iam_access_key_id>
# AWS_SECRET_ACCESS_KEY=<terraform output -raw iam_secret_access_key>
```

**ステップ 3.3: スクリプトの実行**

```bash
# 利用可能な画像のリスト表示
python generate_presigned_url.py --list

# 特定の画像の署名付きURL生成
python generate_presigned_url.py logo.png

# サブフォルダ内の画像
python generate_presigned_url.py products/item-001.jpg
```

##### 3.6 AWS CLI バージョン（シンプル版）

```bash
#!/bin/bash
# generate_presigned_url.sh

BUCKET_NAME="your-bucket-name"
OBJECT_KEY="images/$1"
EXPIRATION=3600  # 1時間

aws s3 presign "s3://${BUCKET_NAME}/${OBJECT_KEY}" \
    --expires-in ${EXPIRATION}
```

使用方法:

```bash
./generate_presigned_url.sh logo.png
```

---

## 実装後の動作確認

### 1. Terraform のデプロイ

```bash
cd S3

# 初回のみ
terraform init

# 設定の確認
terraform plan

# デプロイ
terraform apply

# IAM認証情報の取得（.envファイルに設定）
terraform output -raw iam_access_key_id
terraform output -raw iam_secret_access_key
```

### 2. 画像のアップロード

```bash
# 画像フォルダの作成
mkdir -p upload_file/images

# テスト画像の配置
# (サンプル画像をupload_file/images/に配置)

# 再デプロイで画像をS3にアップロード
terraform apply
```

### 3. 署名付き URL の生成と検証

```bash
cd scripts

# 環境設定
pip install -r requirements.txt
cp .env.example .env
# .envファイルを編集

# 画像リストの確認
python generate_presigned_url.py --list

# URLの生成
python generate_presigned_url.py test-image.png

# URLの動作確認（ブラウザまたはcurl）
curl -I "<生成されたURL>"
```

---

## セキュリティベストプラクティス

### 認証情報の管理

- **.env ファイルを gitignore に追加**

  ```bash
  echo ".env" >> .gitignore
  ```

- **AWS Systems Manager Parameter Store の利用**（本番環境推奨）

  ```python
  import boto3

  ssm = boto3.client('ssm')
  response = ssm.get_parameter(
      Name='/myapp/s3/access_key',
      WithDecryption=True
  )
  access_key = response['Parameter']['Value']
  ```

### URL 有効期限の設定指針

| 用途               | 推奨有効期限       |
| ------------------ | ------------------ |
| 一時的なプレビュー | 300 秒 (5 分)      |
| ダウンロードリンク | 3600 秒 (1 時間)   |
| 共有リンク         | 86400 秒 (24 時間) |
| 長期アクセス       | CloudFront 推奨    |

### アクセスログの有効化

```hcl
# main.tfに追加
resource "aws_s3_bucket_logging" "example" {
  bucket = aws_s3_bucket.example.id

  target_bucket = aws_s3_bucket.logs.id
  target_prefix = "s3-access-logs/"
}
```

---

## トラブルシューティング

### よくある問題と解決方法

#### 1. 認証エラー

**エラー**: `NoCredentialsError: Unable to locate credentials`

**解決方法**:

- `.env`ファイルが正しく設定されているか確認
- AWS 認証情報が有効か確認
- `terraform output`で IAM アクセスキーを再取得

#### 2. 権限エラー

**エラー**: `AccessDenied: Access Denied`

**解決方法**:

- IAM ポリシーが正しくアタッチされているか確認
- バケット名が正しいか確認
- オブジェクトキーのパスが正しいか確認（`images/`プレフィックス）

#### 3. オブジェクトが見つからない

**エラー**: `404 Not Found`

**解決方法**:

```bash
# S3内のオブジェクトを確認
aws s3 ls s3://your-bucket-name/images/ --recursive

# Terraformで再アップロード
terraform apply -replace="aws_s3_object.upload_images[\"filename.png\"]"
```

---

## 次のステップ: CloudFront との統合（将来実装）

### フェーズ 2 の概要

1. **CloudFront ディストリビューションの作成**

   - S3 をオリジンとして設定
   - Origin Access Identity (OAI) の設定

2. **署名付き Cookie または署名付き URL の実装**

   - より高速な配信
   - より細かいアクセス制御

3. **キャッシュ戦略の最適化**
   - TTL 設定
   - キャッシュ無効化の自動化

### ハイブリッド構成のメリット

- **パフォーマンス**: CloudFront のエッジロケーションでキャッシュ
- **コスト**: データ転送料の削減
- **セキュリティ**: 直接 S3 アクセスをブロック
- **柔軟性**: 用途に応じて S3 直接アクセスと CloudFront 経由を使い分け

---

## 関連リソース

### AWS 公式ドキュメント

- [S3 署名付き URL](https://docs.aws.amazon.com/AmazonS3/latest/userguide/ShareObjectPreSignedURL.html)
- [IAM ポリシーとバケットポリシー](https://docs.aws.amazon.com/AmazonS3/latest/userguide/access-policy-language-overview.html)
- [S3 セキュリティベストプラクティス](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)

### Terraform ドキュメント

- [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy)
- [aws_iam_user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user)
- [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)
- [aws_s3_object](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object)

### boto3 ドキュメント

- [generate_presigned_url](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html#S3.Client.generate_presigned_url)
- [S3 Client](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html)

---

## まとめ

このプランに従って実装することで:

✅ セキュアな画像配信システムの構築  
✅ プライベート S3 バケットの維持  
✅ 一時的なアクセス権限の付与  
✅ 将来的な CloudFront 統合への準備

段階的に実装を進め、必要に応じて CloudFront とのハイブリッド構成に移行できる柔軟な設計となっています。

---

## 実装進捗状況

### ステップ 1: 署名付き URL 生成用の IAM ポリシー追加 ✅ 完了

**実装日**: 2025-11-29

**実装内容**:

- ✅ `variables.tf` に IAM ユーザー/ロール作成用の変数を追加

  - `create_iam_user`: IAM ユーザー作成フラグ（デフォルト: true）
  - `create_iam_role`: IAM ロール作成フラグ（デフォルト: false）
  - `iam_role_service`: ロールのサービスプリンシパル（デフォルト: lambda.amazonaws.com）

- ✅ `iam.tf` の作成

  - IAM ポリシー: `s3:GetObject` と `s3:ListBucket` 権限
  - IAM ユーザー: ローカル開発用（アクセスキー付き）
  - IAM ロール: Lambda/EC2 用

- ✅ `outputs.tf` に IAM 関連の出力を追加
  - IAM ユーザー名と ARN
  - アクセスキー ID とシークレットキー（sensitive 設定）
  - IAM ロール名と ARN

**次のステップ**:
ステップ 2 を実行する場合は、以下のプロンプトを使用してください:

```
ステップ2を実行してください。
進捗状況を同マークダウンファイルに追記してください。
```

---

### ステップ 2: 画像専用プレフィックスの設定 ⏳ 未実装

**実装予定内容**:

- `variables.tf` に画像用の変数を追加
- `main.tf` に画像アップロード設定を追加
- `upload_file/images/` ディレクトリの作成
- `outputs.tf` に画像パス情報を追加

**次のステップ**:
ステップ 2 を実行する場合は、以下のプロンプトを使用してください:

```
ステップ2を実行してください。
進捗状況を同マークダウンファイルに追記してください。
```

---

### ステップ 3: URL 生成スクリプトの作成 ⏳ 未実装

**実装予定内容**:

- `S3/scripts/` ディレクトリの作成
- Python スクリプトの作成
  - `generate_presigned_url.py`: 署名付き URL 生成スクリプト
  - `requirements.txt`: 依存パッケージ
  - `.env.example`: 環境変数テンプレート

**次のステップ**:
ステップ 3 を実行する場合は、以下のプロンプトを使用してください:

```
ステップ3を実行してください。
進捗状況を同マークダウンファイルに追記してください。
```

---

## 実装後の確認コマンド

### Terraform のデプロイ

```bash
cd S3

# 設定の確認
terraform plan

# デプロイ
terraform apply

# IAM認証情報の取得
terraform output -raw iam_access_key_id
terraform output -raw iam_secret_access_key
```

### エラーチェック

```bash
# Terraformの構文チェック
terraform validate

# フォーマットチェック
terraform fmt -check
```
