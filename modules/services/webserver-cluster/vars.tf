variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}

variable "cluster_name" {
  description = "The name to use for all cluster resources"
}

variable "db_remote_state_bucket" {
  description = "The name of the S3 bucket to use for databse's remote state"
}

variable "db_remote_state_key" {
  description = "The path for the database's remote key in the S3 bucket"
}

variable "instance_type" {
  description = "The type of EC2 instance to run (e.g. t2.micro)"
}

variable "min_size" {
  description = "The minimum number of EC2 instances in ASG"
}

variable "max_size" {
  description = "The maximum number of EC2 instances in ASG"
}

variable "enable_autoscheduling" {
  description = "If set to true, enable auto scaling"
}