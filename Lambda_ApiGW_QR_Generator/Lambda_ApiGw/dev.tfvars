# ---------------------------------------------
# main.tf
# ---------------------------------------------
aws_region  = "ap-northeast-1" # 東京リージョン
aws_profile = "AdministratorAccess-339126664118"

# ---------------------------------------------
# outputs.tf
# ---------------------------------------------
environment = "dev"
is_windows  = true # Windows環境の場合はtrue、Linux/Macの場合はfalse
