variable "aws_profile" {
   description = "the profile to use when destorying the VPC. Uses the default profile by default"
   type            = string 
   default        = "default"
}

variable "aws_region" {
  type            = list(string)
}