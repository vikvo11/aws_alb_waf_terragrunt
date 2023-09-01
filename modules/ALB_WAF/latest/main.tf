resource "aws_default_subnet" "default_az1" {
  availability_zone = var.availability_zones[0]
  tags = {
    Name = "Default subnet for ${var.availability_zones[0]}"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = var.availability_zones[1]

  tags = {
    Name = "Default subnet for ${var.availability_zones[1]}"
  }
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

#SG- 
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2_security_group-${var.env}"
  description = "ec2_security_group"
  vpc_id      = aws_default_vpc.default.id

  tags = {
    Name = "ec2_security_group-${var.env}"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_security_group" {
  name        = "alb_security_group-${var.env}"
  description = "alb_security_group"
  vpc_id      = aws_default_vpc.default.id

  tags = {
    Name = "alb_security_group-${var.env}"
  }

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


}
###
### ALB
resource "aws_lb" "waf_acme_lb" {
  name               = "waf-acme-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_security_group.id]
  subnets            = [aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id]
}

### EC2

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}
resource "aws_instance" "web_server" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t3.small"
  #key_name       = "" 

  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  subnet_id              = aws_default_subnet.default_az1.id

  user_data = <<-EOF
              #!/bin/bash
              yum install -y python3
              pip3 install Flask
              cat > /home/ec2-user/echo_server.py <<- EOM
              from flask import Flask, request
              app = Flask(__name__, static_url_path='/custom_static')
              @app.route('/static/<path:path>')
              def custom_static(path):
                  full_url = request.host_url.strip('/') + request.path
                  return full_url
              @app.route('/', defaults={'path': ''})
              @app.route('/<path:path>')
              def echo_path(path):
                  full_url = request.host_url.strip('/') + request.path
                  #full_url = request.host_url.strip('/') + request.path
                  #return path
                  return full_url
              if __name__ == "__main__":
                  app.run(host='0.0.0.0', port=80)
              EOM
              python3 /home/ec2-user/echo_server.py &
              EOF



  tags = {
    Name = "web-server"
  }
}


####
resource "aws_lb_target_group" "target_group" {
  name     = "waf-acme-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_default_vpc.default.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    timeout             = 3
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# Registering an EC2 instance to the target group
resource "aws_lb_target_group_attachment" "target_group_attachment" {
  target_group_arn = aws_lb_target_group.target_group.arn
  target_id        = aws_instance.web_server.id
  port             = 80
}

# Creating a listening rule to redirect traffic from ALB to the target group
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.waf_acme_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}




resource "aws_wafv2_web_acl" "waf_acl" {
  name        = "waf-acme-acl"
  description = "WAFv2 ACL for waf-acme-lb"
  scope       = "REGIONAL"

  default_action {
    block {} # Block traffic by default
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "exampleWAFMetric"
    sampled_requests_enabled   = true
  }

  dynamic "rule" {
    for_each = var.whitelist

    content {
      name     = "whitelist-${rule.key}"
      priority = rule.key

      action {
        allow {}
      }

      statement {
        and_statement {
          statement {
            regex_pattern_set_reference_statement {
              arn = aws_wafv2_regex_pattern_set.host_patterns[rule.key].arn
              field_to_match {
                single_header {
                  name = "host"
                }
              }
              text_transformation {
                priority = 1
                type     = "NONE"
              }
            }
          }

          ###
          # # Adding X-API-Key check
          # statement {
          #   byte_match_statement {
          #     field_to_match {
          #       single_header {
          #         name = "x-api-key"
          #       }
          #     }
          #     positional_constraint = "EXACTLY"
          #     search_string         = rule.value.api_key
          #     text_transformation {
          #       priority = 1
          #       type     = "NONE"
          #     }
          #   }
          # }
          # ###

          statement {
            regex_pattern_set_reference_statement {
              arn = aws_wafv2_regex_pattern_set.path_patterns[rule.key].arn
              field_to_match {
                uri_path {}
              }
              text_transformation {
                priority = 1
                type     = "NONE"
              }
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = false
        metric_name                = "whitelist-rule-${rule.key}-metric"
        sampled_requests_enabled   = false
      }
    }
  }
}

resource "aws_wafv2_regex_pattern_set" "host_patterns" {
  for_each = { for idx, wl in var.whitelist : idx => wl }
  name     = "host-pattern-${each.key}"
  scope    = "REGIONAL"

  regular_expression {
    regex_string = each.value.host_regex
  }
}

resource "aws_wafv2_regex_pattern_set" "path_patterns" {
  for_each = { for idx, wl in var.whitelist : idx => wl }
  name     = "path-pattern-${each.key}"
  scope    = "REGIONAL"

  regular_expression {
    regex_string = each.value.path_regex
  }
}
###
# Binding WAFv2 to ALB
resource "aws_wafv2_web_acl_association" "waf_alb_association" {
  web_acl_arn  = aws_wafv2_web_acl.waf_acl.arn
  resource_arn = aws_lb.waf_acme_lb.arn
}
####
output "whitelisted_patterns" {
  value = [
    for item in var.whitelist : "${item.host_regex}${item.path_regex}"
  ]
  description = "List of whitelisted host and path patterns."
}
###
output "alb_dns_name" {
  value = aws_lb.waf_acme_lb.dns_name
}

#######
output "module_version" {
  value = var.module_version
}
output "availability_zones" {
  value = var.availability_zones

}
output "subnets" {
  value = aws_default_subnet.default_az1.id

}