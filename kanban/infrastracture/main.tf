module "lambda_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  create_role = true
  role_path = "/kanban/"
  role_name = "kanban-backend-lambda"
  role_requires_mfa = false
  trusted_role_services = ["lambda.amazonaws.com"]
}
