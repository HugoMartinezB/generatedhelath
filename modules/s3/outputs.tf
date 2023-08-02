output "bucket_name" {
  value = aws_s3_bucket.this.id
}

output "topic_arn" {
  value = aws_sns_topic.this.arn
}