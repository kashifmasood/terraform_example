data "terraform_remote_state" "db" {
  backend = "s3"

  config {
    bucket = "${var.db_remote_state_bucket}"
    key = "${var.db_remote_state_key}"
    region = "us-east-1"
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.sh")}"

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
  instance_type = "${var.instance_type}"

  security_groups = ["${aws_security_group.launch-config-security-group.id}"]

  user_data = "${data.template_file.user_data.rendered}"

  name = "${var.cluster_name}-launch-configuration!"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "launch-config-security-group" {
  name = "${var.cluster_name}-secutiry-group"
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
  name = "${var.cluster_name}-elb"

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
  name = "${var.cluster_name}-elb-security-group"
}


resource "aws_security_group_rule" "allow-http_inbound" {
  type = "ingress"

  security_group_id = "${aws_security_group.elb-security-group.id}"

  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow-http_outbound" {
  type = "egress"

  security_group_id = "${aws_security_group.elb-security-group.id}"

  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"]
}

// -------------------------------------------------------------------

resource "aws_autoscaling_group" "example" {
  launch_configuration = "${aws_launch_configuration.example_launch_config.id}"
  availability_zones = ["${data.aws_availability_zones.all.names}"]

  load_balancers = ["${aws_elb.example.name}"]
  health_check_type = "ELB"

  min_size = "${var.min_size}"
  max_size = "${var.max_size}"

  tag {
    key = "Name"
    value = "${var.cluster_name}"
    propagate_at_launch = true
  }
}
