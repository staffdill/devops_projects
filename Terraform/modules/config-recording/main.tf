resource "aws_config_configuration_recorder_status" "config_recorder_status" {
  is_enabled = true
  name = "aws-config-recording-${data.aws_region.current.name}"
  depends_on = [aws_config_delivery_channel.config_channel, aws_config_configuration_recorder.config_recorder]
}

resource "aws_config_delivery_channel" "config_channel" {
  s3_bucket_name = "aws-global-config-logging-${var.deploy_account_id}"
  s3_key_prefix = "Config/${data.aws_region.current.name}/configlogs"
  depends_on = [aws_config_configuration_recorder.config_recorder]
}

resource "aws_config_configuration_recorder" "config_recorder" {
  role_arn = "arn:aws:iam::${var.deploy_account_id}:role/aws-config-recorder-role"
  name = "aws-config-recording-${data.aws_region.current.name}"
  recording_group {
    all_supported = true
    include_global_resource_type = false
  }
}

data "aws_region" "current" {}