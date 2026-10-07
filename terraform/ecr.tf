resource "aws_ecr_repository" "spark" {
  name                 = "spark"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "spark"
  }
}

