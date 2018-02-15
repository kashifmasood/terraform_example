provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "km-terraform-state"
    key = "stage/data-sources/mysql/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

resource "aws_db_instance" "example" {
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "km_example_database"
  username = "admin"
  password = "${var.db_password}"
}