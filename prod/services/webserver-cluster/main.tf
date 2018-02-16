provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "km-terraform-state"
    key = "prod/services/webserver-cluster/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "km-webserver-prod"
  db_remote_state_bucket = "km-terraform-prod"
  db_remote_state_key = "prod/data-sources/mysql/terraform.tfstate"
  instance_type = "t2.micro"
  min_size = "2"
  max_size = "10"
}