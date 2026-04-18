locals {
  alb_https_enabled = var.alb_certificate_arn != ""
}

resource "aws_lb" "app" {
  name               = "${local.deploy_name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.alb_security_group_id]
  subnets            = var.public_subnet_ids
  tags               = local.common_tags
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = local.alb_https_enabled ? "redirect" : "forward"
    target_group_arn = local.alb_https_enabled ? null : var.target_group_arn

    dynamic "redirect" {
      for_each = local.alb_https_enabled ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = local.alb_https_enabled ? 1 : 0
  load_balancer_arn = aws_lb.app.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.alb_certificate_arn
  ssl_policy        = var.alb_ssl_policy

  default_action {
    type             = "forward"
    target_group_arn = var.target_group_arn
  }
}
