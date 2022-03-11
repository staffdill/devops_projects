variable "aws_profile" {
   description = "the profile to use when destorying the VPC. Uses the default profile by default"
   type            = string 
   default        = "default"
}

variable "aws_regions_cleanup" {
  type            = list(string)
  default        =  ["us-west-1", "us-west-2", "us-east-1", "us-east-2"]
}