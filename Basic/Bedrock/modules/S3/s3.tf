resource "aws_s3_bucket" "obsidian_data" {
  bucket = "my-sample-bedrock-data-${random_id.id.hex}"
}

resource "random_id" "id" {
  byte_length = 4
}
