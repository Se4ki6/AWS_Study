resource "aws_amplify_app" "this" {
  name         = var.app_name
  repository   = var.github_repository_url
  access_token = var.github_token

  # ViteやNext.js(SSG)などの標準的なビルド設定に最適化
  build_spec = <<-EOT
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: dist
        files:
          - '**/*'
      cache:
        paths:
          - node_modules/**/*
  EOT

  # SPA（React等）でリロードした時に404になるのを防ぐための「リダイレクト設定」
  # これがないと、/mypage とかでリロードした時にエラーになっちゃうんだ
  custom_rule {
    source = "/<*>"
    target = "/index.html"
    status = "404-200"
  }
}

resource "aws_amplify_branch" "main" {
  app_id            = aws_amplify_app.this.id
  branch_name       = "main"
  enable_auto_build = true
}
