provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "km-terraform-state"
    key = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

module "webserver_cluster" {
  source = "../../../modules/services/webserver-cluster"

  cluster_name = "km-webserver-stage"
  db_remote_state_bucket = "km-terraform-state"
  db_remote_state_key = "stage/data-sources/mysql/terraform.tfstate"
  instance_type = "t2.micro"
  min_size = "2"
  max_size = "2"
  enable_autoscheduling = false
}