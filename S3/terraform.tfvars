// variables.tfで定義した変数に実際の値を設定するファイル
// このファイルはGitにコミットしない場合もある (機密情報を含む場合)

// S3バケット名
// 注意: バケット名はAWS全体で一意である必要があるため、
// 適切な命名規則 (組織名-プロジェクト名-環境-日付など) を使用すること
bucket_name = "my-unique-bucket-name-20251122"

// 環境名
// dev: 開発環境, staging: ステージング環境, prod: 本番環境
environment = "dev"

// アップロードするローカルファイルのパス
source_path = "upload_file/example.txt"

// S3バケット内でのオブジェクトキー (ファイル名)
object_key = "example.txt"
