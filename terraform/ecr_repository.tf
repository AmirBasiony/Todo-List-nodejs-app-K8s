# ECR Repository for storing Docker images
data "aws_ecr_repository" "app_ecr" {
  name = "todo-nodejs-app"
}