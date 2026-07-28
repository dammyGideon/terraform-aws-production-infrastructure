############################################################
# Ubuntu AMI
############################################################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################################################
# IAM Role
############################################################

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-ec2-role"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

//this gives the Ec2 permission to send Telementry data to CloudWatch
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}


resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2.name
}

############################################################
# Launch Template
############################################################

resource "aws_launch_template" "app" {

  name_prefix   = "${var.project_name}-${var.environment}-app-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2.name
  }

  vpc_security_group_ids = [
    var.app_security_group_id
  ]

user_data = base64encode(templatefile("${path.module}/../../scripts/bootstrap.sh", {
  install_nginx_script = file("${path.module}/../../scripts/install-nginx.sh")
  install_cloudwatch_script = file("${path.module}/../../scripts/install-cloudwatch.sh")
  cloudwatch_config = templatefile("${path.module}/../../scripts/amazon-cloudwatch-agent.json", {})
}))

  metadata_options {
    http_tokens = "required"
  }

  monitoring {
    enabled = true
  }

  block_device_mappings {

    device_name = "/dev/sda1"

    ebs {
      volume_size           = 30
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {

    resource_type = "instance"

    tags = {
      Name        = "${var.project_name}-${var.environment}-app"
      Project     = var.project_name
      Environment = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-launch-template"
    Project     = var.project_name
    Environment = var.environment
  }
}

############################################################
# Application Load Balancer
############################################################
#    = "${var.project_name}-${var.environment}-alb-sg"

resource "aws_lb" "this" {

  name               = "${var.project_name}-${var.environment}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    var.alb_security_group_id
  ]

  subnets = var.public_subnets_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Project     = var.project_name
    Environment = var.environment
  }
}

############################################################
# Target Group
############################################################

resource "aws_lb_target_group" "app" {

  name     = "${var.project_name}-${var.environment}-app-tg"
  port     = 80
  protocol = "HTTP"

  vpc_id = var.vpc_id

  health_check {

    enabled = true

    path = "/health"

    protocol = "HTTP"

    matcher = "200"

    interval = 30

    timeout = 5

    healthy_threshold = 2

    unhealthy_threshold = 3
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-tg"
    Project     = var.project_name
    Environment = var.environment
  }
}

############################################################
# HTTP Listener
############################################################

resource "aws_lb_listener" "http" {

  load_balancer_arn = aws_lb.this.arn

  port = 80

  protocol = "HTTP"

  default_action {

    type = "forward"

    target_group_arn = aws_lb_target_group.app.arn
  }





}

resource "aws_autoscaling_group" "app" {
  name = "${var.project_name}-${var.environment}-asg"

  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  vpc_zone_identifier = var.private_subnets_ids

  target_group_arns = [
    aws_lb_target_group.app.arn
  ]

  health_check_type         = "ELB"
  health_check_grace_period = 300

//Instead of allowing the ASG to use whichever launch-template version happens to be latest:
# launch_template {
#   id      = aws_launch_template.app.id
#   version = "$Latest"
# }

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 300
    }
  }
   enabled_metrics = [
          "GroupMinSize",
          "GroupMaxSize",
          "GroupDesiredCapacity",
          "GroupInServiceInstances",
          "GroupPendingInstances",
          "GroupTerminatingInstances",
          "GroupTotalInstances"
    ]
  metrics_granularity = "1Minute"
  tag {
    key                 = "Name"
    value               = "${var.project_name}-${var.environment}-app"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }



}

resource "aws_autoscaling_policy" "cpu_target" {
  name           = "${var.project_name}-${var.environment}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type    = "TargetTrackingScaling"


  estimated_instance_warmup = 300

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
