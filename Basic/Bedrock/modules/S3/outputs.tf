output "bucket_arn" {
  value = aws_s3_bucket.obsidian_data.arn
}

output "random_id_hex" {
  value = random_id.id.hex
}
