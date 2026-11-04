resource "aws_ecr_repository" "user_service" {
  name                 = "user-service"
  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecr_repository" "product_service" {
  name                 = "product-service"
  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_ecr_repository" "order_service" {
  name                 = "order-service"
  image_tag_mutability = "MUTABLE"

  lifecycle {
    prevent_destroy = true
  }
}
