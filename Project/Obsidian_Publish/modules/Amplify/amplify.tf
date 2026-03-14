resource "aws_amplify_app" "this" {
  name = var.app_name

  # GitHub ActionsがQuartzのビルドとS3アップロードを行うため
  # Amplify側のビルドは不要 → build_specもリポジトリ連携も設定しない
}

resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.this.id
  branch_name = "main"

  # ビルドはGitHub Actionsに任せるため無効
  enable_auto_build = false
}
