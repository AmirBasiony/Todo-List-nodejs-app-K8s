###############################
#        EC2 INSTANCE        #
###############################
resource "aws_instance" "WebServer_K8s" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet_K8s.id
  security_groups             = [aws_security_group.WebTrafficSG_K8s.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile_K8s.name
  associate_public_ip_address = true
  key_name                    = "todo-app-ssh-key"

  tags = {
    Name = "WebServer_K8s"
  }
}
