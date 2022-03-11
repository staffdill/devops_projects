provider "aws" {
  alias = "us-west-1"
  region = 'us-west-1'
}

module "config-us-west-1"{
  source = "../modules/config-recording"
  providers = {
    aws = aws.us-west-1
  }
}

provider "aws" {
  alias = "us-west-2"
  region = 'us-west-2'
}

module "config-us-west-2"{
  source = "../modules/config-recording"
  providers = {
    aws = aws.us-west-2
  }
}

provider "aws" {
  alias = "us-east-1"
  region = 'us-east-1'
}

module "config-us-east-1"{
  source = "../modules/config-recording"
  providers = {
    aws = aws.us-east-1
  }
}

provider "aws" {
  alias = "us-east-2"
  region = 'us-east-2'
}

module "config-us-east-2"{
  source = "../modules/config-recording"
  providers = {
    aws = aws.us-east-2
  }
}


resource "aws_s3_bucket" "config_logging" {
  bucket = "aws-global-config-logging-${local.deploy_account_id}"
  acl = "private"
  provider = aws.us-west-2

  server_side_encryption_configuration {
    rule {
      apply_server_side_enctyption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  lifecycle_rule {
    id      = "log"
    enabled = true
    prefix  = "logs/"

    transition {
      storage_class = "GLACIER"
      days          = 30
    }

    expiratoin {
      days = 365
    }

  }
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  provider = aws.us-west-2
  bucket = aws_s3_bucket.config_logging
  policy = data.aws_iam_policy_document.config_bucket_policy.json
  depends_on = [aws_s3_bucket_public_access_block.config_logging_block]
}

resource "aws_s3_bucket_public_access_block" "config_logging_block" {
  provider = aws.us-west-2
  bucket   = aws_s3_bucket.config_logging.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "config_bucket_policy" {
  provider = aws.us-west-2
  statement {
    sid     = "AllowSSLRequestsOnly"
    actions = ["s3:*"]
    effect  = "Deny"
    resources = [
      aws_s3_bucket.config_logging.arn,
      "${aws_s3_bucket.config_logging.arn}/*"
    ]
    condition {
      test      = "Bool"
      variable  = "aws:SecureTransport"
      values    = ["False"]
    }
    principals {
      type = "*"
      identifiers = ["*"]
    }
  }

  statement {
    sid       = "Config write to bucket"
    principals {
      identifies = ["config.amazonaws.com"]
      type = "Service"
    }
    actions = ["s3:PutObject"]
    resources = [
      aws_s3_bucket.config_logging.arn,
      "${aws_s3_bucket.config_logging.arn}/*"
    ]
  }

  statment {
    sid = "allow bucket acl check"
    effect = "Allow"
    principals {
      identifies = ["config.amazonaws.com"]
      type = "Service"
    }
    actions = ["s3:GetBucketAcl"]
    resources = [
      aws_s3_bucket.config_logging.arn,
      "${aws_s3_bucket.config_logging.arn}/*"
    ]
  }
}

resource "aws_iam_role" "recording_role" {
  provider = aws.us-west-2
  name = "aws-config-recording-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
      }
    ]
  }
POLICY
}

resource "aws_iam_role_policy_attachment" "aws_config_role_attachment" {
  provider = aws.us-west-2
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
  role = aws_iam_role.recording_role.name
}

resource "aws_iam_role_policy" "recorder_policy" {
  provider = aws.us-west-2
  name = "aws-config-role"
  role = aws_iam_role.recording_role.id

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statment": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      resources = [
      aws_s3_bucket.config_logging.arn,
      "${aws_s3_bucket.config_logging.arn}/*"
    ]
  }
POLICY
}

