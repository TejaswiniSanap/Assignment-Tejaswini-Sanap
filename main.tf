terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.53.0"
    }
  }

  required_version = ">= 0.15"
}

provider "aws" {
  region = "us-east-1"
  access_key = "AKIAVLURVZZQRFGBA6VX"
  secret_key = "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"
  

  default_tags {
    tags = {
      hashicorp = "aws-asg"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.77.0"

  name = "main-vpc"
  cidr = "10.0.0.0/16"

  azs                  = data.aws_availability_zones.available.names
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_security_group" "website_lb" {
  name = "asg-website-lb"
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

  vpc_id = module.vpc.vpc_id


}


resource "aws_lb_listener" "website" {
  load_balancer_arn = aws_lb.website.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.website.arn
  }
}
resource "aws_security_group" "website_instance" {
  name = "asg-website-instance"
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
  }
ingress{

    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.website_lb.id]
    
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = module.vpc.vpc_id
}
resource "aws_lb_target_group" "website" {
  name     = "asg-website"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
}
resource "aws_lb" "website" {
  name               = "asg-website-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.website_lb.id]
  subnets            = module.vpc.public_subnets
}

resource "aws_launch_template" "webiste" {
  name = "terraform-aws-asg-"
  image_id =  data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

   block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }

  vpc_security_group_ids = [aws_security_group.website_instance.id]

  user_data = base64encode("<<-EOF #!/bin/bash sudo apt update -y sudo apt install apache2 -y echo “Welcome to $(hostname -f)” > /var/www/html/index.html EOF")


}

resource "aws_autoscaling_group" "website" {
  name                 = "website"
  min_size             = 2
  max_size             = 4
  desired_capacity     = 2
  launch_configuration = aws_launch_configuration.website.name
  vpc_zone_identifier  = module.vpc.public_subnets
  target_group_arns = [aws_lb_target_group.website.arn]


  tag {
    key                 = "Name"
    value               = "Demo - website"
    propagate_at_launch = true
  }
}
/*resource "aws_launch_configuration" "webiste" {
  name_prefix     = "terraform-aws-asg-"
  image_id        = data.aws_ami.amazon-linux.id
  instance_type   = "t2.micro"
  user_data       = file("user-data.sh")
  security_groups = [aws_security_group.website_instance.id]

  lifecycle {
    create_before_destroy = true
  }
}*/




# resource "aws_autoscaling_attachment" "website" {
#   autoscaling_group_name = aws_autoscaling_group.website.id
#   alb_target_group_arn   = aws_lb_target_group.website.arn
# }



