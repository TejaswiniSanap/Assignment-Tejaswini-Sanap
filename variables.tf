
# data "aws_ami" "amazon-linux" {
#   most_recent = true
#   owners      = ["amazon"]

#   filter {
#     name   = "name"
#     values = ["amzn-ami-hvm-*-x86_64-ebs"]
    
#   }
# }
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}
resource "aws_launch_configuration" "website" {

  image_id = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  name = "website"
  security_groups = [aws_security_group.website_instance.id]


  root_block_device {
    volume_type = "gp2"
    volume_size = "20"
  }
}


