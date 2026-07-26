data "aws_region" "current" {}

resource "aws_cloudwatch_dashboard" "operations" {
  dashboard_name = "${var.project_name}-${var.environment}-operations"

  dashboard_body = jsonencode({
    start          = "-PT3H"
    periodOverride = "inherit"

    widgets = [
      {
        type   = "text"
        x      = 0
        y      = 0
        width  = 24
        height = 2

        properties = {
          markdown = <<-EOT
            # ${upper(var.project_name)} ${upper(var.environment)} Operations Dashboard

            **Traffic flow:** Internet → ALB → Listener → Target Group → EC2 → Nginx → Application
          EOT
        }
      },

      # ---------------------------------------------------------
      # Widget 1: Availability
      # ---------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 2
        width  = 12
        height = 6

        properties = {
          title   = "Target Availability"
          region  = data.aws_region.current.name
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Minimum"

          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              "TargetGroup",
              var.target_group_arn_suffix,
              {
                label = "Healthy targets"
              }
            ],
            [
              "AWS/ApplicationELB",
              "UnHealthyHostCount",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              "TargetGroup",
              var.target_group_arn_suffix,
              {
                label = "Unhealthy targets"
              }
            ]
          ]
        }
      },

      # ---------------------------------------------------------
      # Widget 2: Traffic and errors
      # ---------------------------------------------------------
      {
        type   = "metric"
        x      = 12
        y      = 2
        width  = 12
        height = 6

        properties = {
          title   = "Requests and HTTP Errors"
          region  = data.aws_region.current.name
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Sum"

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              {
                label = "Requests"
              }
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              {
                label = "ALB 5XX"
              }
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              "TargetGroup",
              var.target_group_arn_suffix,
              {
                label = "Target 5XX"
              }
            ]
          ]
        }
      },

      # ---------------------------------------------------------
      # Widget 3: Latency
      # ---------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 8
        width  = 12
        height = 6

        properties = {
          title   = "Target Response Time"
          region  = data.aws_region.current.name
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Average"
          yAxis = {
            left = {
              label     = "Seconds"
              showUnits = true
              min       = 0
            }
          }

          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              var.load_balancer_arn_suffix,
              "TargetGroup",
              var.target_group_arn_suffix,
              {
                label = "Average response time"
              }
            ]
          ]
        }
      },

      # ---------------------------------------------------------
      # Widget 4: ASG capacity
      # ---------------------------------------------------------
      {
        type   = "metric"
        x      = 12
        y      = 8
        width  = 12
        height = 6

        properties = {
          title   = "Auto Scaling Capacity"
          region  = data.aws_region.current.name
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Average"

          metrics = [
            [
              "AWS/AutoScaling",
              "GroupDesiredCapacity",
              "AutoScalingGroupName",
              var.autoscaling_group_name,
              {
                label = "Desired"
              }
            ],
            [
              "AWS/AutoScaling",
              "GroupInServiceInstances",
              "AutoScalingGroupName",
              var.autoscaling_group_name,
              {
                label = "In service"
              }
            ],
            [
              "AWS/AutoScaling",
              "GroupPendingInstances",
              "AutoScalingGroupName",
              var.autoscaling_group_name,
              {
                label = "Pending"
              }
            ],
            [
              "AWS/AutoScaling",
              "GroupTerminatingInstances",
              "AutoScalingGroupName",
              var.autoscaling_group_name,
              {
                label = "Terminating"
              }
            ]
          ]
        }
      },

      # ---------------------------------------------------------
      # Widget 5: Resource saturation
      # ---------------------------------------------------------
      {
        type   = "metric"
        x      = 0
        y      = 14
        width  = 24
        height = 6

        properties = {
          title   = "Average EC2 CPU Utilization"
          region  = data.aws_region.current.name
          view    = "timeSeries"
          stacked = false
          period  = 60
          stat    = "Average"
          yAxis = {
            left = {
              label     = "Percent"
              showUnits = true
              min       = 0
              max       = 100
            }
          }

          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              var.autoscaling_group_name,
              {
                label = "ASG average CPU"
              }
            ]
          ]
        }
      }
    ]
  })
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name        = "${var.project_name}-${var.environment}-unhealthy-targets"
  alarm_description = "All ALB nodes consistently detect one or more unhealthy targets"

  namespace   = "AWS/ApplicationELB"
  metric_name = "UnHealthyHostCount"
  statistic   = "Minimum"

  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2

  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  treat_missing_data = "notBreaching"

  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions =[
    aws_sns_topic.operations_alerts.arn
  ]
  ok_actions = [
    aws_sns_topic.operations_alerts.arn
  ]


  tags = {
    Name        = "${var.project_name}-${var.environment}-unhealthy-targets"
    Project     = var.project_name
    Environment = var.environment
  }
}



resource "aws_sns_topic" "operations_alerts" {
  name = "${var.project_name}-${var.environment}-operations-alerts"

  tags = {
    Name        = "${var.project_name}-${var.environment}-operations-alerts"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.operations_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}