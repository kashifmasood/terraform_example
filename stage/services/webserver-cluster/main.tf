provider "aws" {
  region = "us-east-1"
  version = "~> 1.8"
}

terraform {
  backend "s3" {
    bucket = "km-terraform-state"
    key = "stage/services/webserver-cluster/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    bucket = "km-terraform-state"
    key = "stage/data-sources/mysql/terraform.tfstate"
    region = "us-east-1"
  }
}

data "template_file" "user_data" {
  template = "${file("user-data.sh")}"

  vars {
    server_port = "${var.server_port}"
    db_address = "${data.terraform_remote_state.db.address}"
    db_port = "${data.terraform_remote_state.db.port}"
  }
}

data "aws_availability_zones" "all" {}

// -------------------------------------------------------------------

resource "aws_launch_configuration" "example_launch_config" {
  image_id = "ami-2d39803a"
  instance_type = "t2.micro"

  security_groups = ["${aws_security_group.launch-config-security-group.id}"]

  user_data = "${data.template_file.user_data.rendered}"

  name = "km-launch-configuration!"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "launch-config-security-group" {
  name = "km-terraform-example-sg"
  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

// -------------------------------------------------------------------

resource "aws_elb" "example" {
  name = "km-terraform-elb-example"

  availability_zones = ["${data.aws_availability_zones.all.names}"]

  security_groups = ["${aws_security_group.elb-security-group.id}"]

  listener {
    instance_port = "${var.server_port}"
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    interval = 30
    target = "HTTP:${var.server_port}/"
    timeout = 3
    unhealthy_threshold = 2
  }
}

resource "aws_security_group" "elb-security-group" {
  name = "km-terraform-example-elb"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

// -------------------------------------------------------------------

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example_launch_config.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "km-terraform-asg_example"
    propagate_at_launch = true
  }
}
