terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws        = ">= 3.72.0"
    local      = ">= 1.4"
    random     = ">= 2.1"
    kubernetes = "~> 2.0"
  }
}