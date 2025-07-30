
variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}
variable "ami" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-0a7d80731ae1b2435"
}

variable "instance_type" {
  description = "Type of EC2 instance"
  default     = "t3.medium"
}

