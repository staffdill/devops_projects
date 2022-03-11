data "aws_region" "current" {}

resource "null_resource" "destroy-vpc" {
    for_each = toset (var.aws_region)
  triggers = {
    aws_region = each.value
    aws_profile = var.aws_profile
  }
  lifecycle {
    ignore_changes = [triggers["aws_profile"]] # Don't trigger if the only the profile changes
  }
  provisioner "local-exec" {
    when        = create
    interpreter = ["PowerShell", "-Command"]
    command     ="& \"${path.module}/destroy-default-vpcs.ps1\" \"${self.triggers.aws_region}\" \"${self.triggers.aws_profile}\""

  }
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["PowerShell", "-Command"]
    command     = "& \"${path.module}/destroy-default-vpcs.ps1\" \"${self.triggers.aws_region}\" \"${self.triggers.aws_profile}\""
  }
}