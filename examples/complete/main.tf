module "alb" {
  source             = "../../"
  name               = "example"
  vpc_id             = "${module.vpc.vpc_id}"
  subnets            = module.vpc.public_subnet_ids
  access_logs_bucket = "${module.s3_lb_log.s3_bucket_id}"
  certificate_arn    = "${module.certificate.acm_certificate_arn}"

  enable_https_listener                  = true
  enable_http_listener                   = true
  enable_redirect_http_to_https_listener = true

  internal                    = false
  idle_timeout                = 120
  enable_http2                = false
  ip_address_type             = "ipv4"
  access_logs_prefix          = "test"
  access_logs_enabled         = true
  ssl_policy                  = "ELBSecurityPolicy-2016-08"
  https_port                  = 443
  http_port                   = 80
  fixed_response_content_type = "text/plain"
  fixed_response_message_body = "ok"
  fixed_response_status_code  = "200"
  ingress_cidr_blocks         = ["0.0.0.0/0"]

  target_group_port                = 80
  target_group_protocol            = "HTTP"
  target_type                      = "ip"
  deregistration_delay             = 600
  slow_start                       = 0
  health_check_path                = "/"
  health_check_healthy_threshold   = 3
  health_check_unhealthy_threshold = 3
  health_check_timeout             = 3
  health_check_interval            = 60
  health_check_matcher             = 200
  health_check_port                = "traffic-port"
  health_check_protocol            = "HTTP"
  listener_rule_priority           = 1
  listener_rule_condition_field    = "path-pattern"
  listener_rule_condition_values   = ["/*"]
  enabled                          = true

  tags = {
    Name        = "complete"
    Environment = "prod"
  }

  # WARNING: If in production environment, you should delete this parameter or change to true.
  enable_deletion_protection = false
}

module "certificate" {
  source      = "git::https://github.com/tmknom/terraform-aws-acm-certificate.git"
  domain_name = "alb.${local.domain_name}"
  zone_id     = "${data.aws_route53_zone.default.id}"
}

module "vpc" {
  source                    = "git::https://github.com/tmknom/terraform-aws-vpc.git?ref=tags/1.0.0"
  cidr_block                = "${local.cidr_block}"
  name                      = "alb"
  public_subnet_cidr_blocks = ["${cidrsubnet(local.cidr_block, 8, 0)}", "${cidrsubnet(local.cidr_block, 8, 1)}"]
  public_availability_zones = ["${data.aws_availability_zones.available.names}"]
}

module "s3_lb_log" {
  source                = "git::https://github.com/tmknom/terraform-aws-s3-lb-log.git?ref=tags/1.0.0"
  name                  = "s3-lb-log-alb-${data.aws_caller_identity.current.account_id}"
  logging_target_bucket = "${module.s3_access_log.s3_bucket_id}"
  force_destroy         = true
}

module "s3_access_log" {
  source        = "git::https://github.com/tmknom/terraform-aws-s3-access-log.git?ref=tags/1.0.0"
  name          = "s3-access-log-alb-${data.aws_caller_identity.current.account_id}"
  force_destroy = true
}

data "aws_route53_zone" "default" {
  name = "${local.domain_name}."
}

locals {
  cidr_block          = "10.255.0.0/16"
  domain_name         = "${var.domain_name != "" ? var.domain_name : local.default_domain_name}"
  default_domain_name = "nellmedina.com"
}

variable "domain_name" {
  default     = "nellmedina.com"
  type        = string
  description = "If TF_VAR_domain_name set in the environment variables, then use that value."
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}
