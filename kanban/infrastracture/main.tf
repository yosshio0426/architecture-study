module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"
  version = "4.12.1"

  function_name = "kanban"
  handler       = "net.yosshio0426.kanban.Handler"
  runtime       = "java11"

  create_package = false
  local_existing_package = "../backend/target/kanban-1.0-SNAPSHOT.jar"

  role_path = "/kanban/"
  role_name = "kanban-backend-lambda"
  policy_path = "/kanban/"
  policy_name = "kanban-backend-logs"
}
