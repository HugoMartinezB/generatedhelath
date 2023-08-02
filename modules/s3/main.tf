
resource "aws_kms_key" "this" {
  description             = "This key is used to encrypt bucket objects"
  deletion_window_in_days = 7
}


resource "aws_kms_alias" "this" {
  name          = "alias/${var.id}"
  target_key_id = aws_kms_key.this.key_id
}


data "aws_iam_policy_document" "sns" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = ["arn:aws:sns:*:*:${var.id}"]

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [aws_s3_bucket.this.arn]
    }
  }
}


resource "aws_sns_topic" "this" {
  name   = var.id
  policy = data.aws_iam_policy_document.sns.json
}



resource "aws_s3_bucket" "this" {
  bucket              = var.id
  force_destroy       = true
  object_lock_enabled = false
  tags = var.tags
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.this.arn
        sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_logging" "this" {
  bucket        = aws_s3_bucket.this.id
  target_bucket = aws_s3_bucket.this.id
  target_prefix = "log/"
}


resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}


// Ensures the buckets ACL are closed off.
resource "aws_s3_bucket_acl" "this" {
  depends_on = [aws_s3_bucket_ownership_controls.this]
  bucket     = aws_s3_bucket.this.id
  acl        = "private"
}


// Ensures buckets versioning is disabled.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = "Disabled"
  }
}

// Ensure public access is off.
resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_metric" "this" {
  bucket = aws_s3_bucket.this.id
  name   = "EntireBucket"
}



resource "aws_s3_bucket_notification" "this" {
  bucket = aws_s3_bucket.this.id

  topic {
    topic_arn     = aws_sns_topic.this.arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]
    //filter_suffix = ".log"
  }
}


// Gets current region so we can add it to global resources.
data "aws_region" "current" {}

resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = aws_s3_bucket.this.id

  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 6,
        "width" : 6,
        "y" : 0,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/S3", "BucketSizeBytes", "StorageType", "StandardStorage", "BucketName", "${aws_s3_bucket.this.id}", { "region" : "${data.aws_region.current.name}" }]
          ],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : "${data.aws_region.current.name}",
          "period" : 86400,
          "stat" : "Sum"
        }
      },
      {
        "height" : 6,
        "width" : 3,
        "y" : 0,
        "x" : 12,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/S3", "NumberOfObjects", "StorageType", "AllStorageTypes", "BucketName", "${aws_s3_bucket.this.id}", { "region" : "${data.aws_region.current.name}" }]
          ],
          "sparkline" : true,
          "view" : "singleValue",
          "region" : "${data.aws_region.current.name}",
          "period" : 86400,
          "stat" : "Sum"
        }
      },
      {
        "height" : 3,
        "width" : 6,
        "y" : 0,
        "x" : 6,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/S3", "GetRequests", "BucketName", "${aws_s3_bucket.this.id}", "FilterId", "EntireBucket"]
          ],
          "sparkline" : true,
          "view" : "singleValue",
          "region" : "${data.aws_region.current.name}",
          "period" : 86400,
          "stat" : "Sum"
        }
      },
      {
        "height" : 3,
        "width" : 6,
        "y" : 3,
        "x" : 6,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/S3", "PutRequests", "BucketName", "${aws_s3_bucket.this.id}", "FilterId", "EntireBucket"]
          ],
          "sparkline" : true,
          "view" : "singleValue",
          "region" : "${data.aws_region.current.name}",
          "period" : 86400,
          "stat" : "Sum"
        }
      },
      {
        "height" : 6,
        "width" : 15,
        "y" : 6,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/S3", "AllRequests", "BucketName", "${aws_s3_bucket.this.id}", "FilterId", "EntireBucket"]
          ],
          "sparkline" : true,
          "view" : "timeSeries",
          "region" : "${data.aws_region.current.name}",
          "period" : 86400,
          "stat" : "Sum"
        }
      }
    ]
  })
}