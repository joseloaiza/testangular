terraform {
  provider "aws" {
    region  = "us-east-1"
  }

   backend "s3" {
    bucket = "terraform-backend-state-jlq" # Will be overridden from build
    key    = "path/to/my/key" # Will be overridden from build
    region = "us-east-1"
  }
}