output "lb_endpoint" {
  value = "http://${aws_lb.website.dns_name}"
}

output "application_endpoint" {
  value = "http://${aws_lb.website.dns_name}/index.html"
}

output "asg_name" {
  value = aws_autoscaling_group.website.name
}