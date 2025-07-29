###############################
#           IAM              #
###############################
resource "aws_iam_role" "ec2_ecr_role_K8s" {
  name = "EC2WithECRRole_K8s"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_attach_K8s" {
  role       = aws_iam_role.ec2_ecr_role_K8s.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_profile_K8s" {
  name = "EC2WithECRProfile_K8s"
  role = aws_iam_role.ec2_ecr_role_K8s.name
}