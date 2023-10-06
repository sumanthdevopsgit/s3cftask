provider "aws" {
  region = "us-west-1"
  access_key = "AKIAQNJKUD7DGHVTQ4KL"
  secret_key = "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"
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = "awss3cfd"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_object" "website" {
  bucket = aws_s3_bucket.my_bucket.bucket
  key    = "index.html"
  source = "C:/Users/vsagiraju/Desktop/cf/index.html"
  acl    = "private"
  content_type = "text/html"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "S3 Origin Identity for my_bucket"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.bucket

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          AWS = "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${aws_cloudfront_origin_access_identity.origin_access_identity.id}"
        },
        Action   = "s3:GetObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.my_bucket.bucket}/*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = "myS3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "myS3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.my_bucket.arn
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}
