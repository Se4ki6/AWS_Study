# ---------------------------------------------
# main.tf
# ---------------------------------------------
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-1"
}
variable "aws_profile" {
  description = "AWS SSO Profile"
  type        = string
  default     = "AdministratorAccess-339126664118"
}

# ---------------------------------------------
# Environment Configuration
# ---------------------------------------------
variable "environment" {
  description = "Environment (dev or prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

