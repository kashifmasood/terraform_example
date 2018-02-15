provider "aws" {
  region = "us-east-1"
  version = "~> 1.8"
}

terraform {
  backend "s3" {
    bucket = "km-terraform-state"
    key = "global/s3/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "km-terraform-state"

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = true
  }
}

