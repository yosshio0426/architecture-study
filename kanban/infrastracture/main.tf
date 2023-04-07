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

  cloudwatch_logs_retention_in_days = 7

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/$default"
    }
  }
}

resource "aws_cloudwatch_log_group" "api_gateway_log" {
  name = "/kanban/api-access"

  retention_in_days = 7
}

module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"
  version = "2.2.2"

  name = "kanban"
  protocol_type = "HTTP"

  create_api_domain_name = false

  integrations = {
    "$default" = {
      lambda_arn = module.lambda_function.lambda_function_arn
      payload_format_version = "2.0"
    }
  }

  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.api_gateway_log.arn
  default_stage_access_log_format = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"
}

module "dynamodb-table" {
  source  = "terraform-aws-modules/dynamodb-table/aws"
  version = "3.2.0"

  name = "kanban"

  billing_mode = "PAY_PER_REQUEST"

  attributes = [
    {
      name = "kanban-physical-id"
      type = "S"
    },
    {
      name = "entity-physical-id"
      type = "S"
    },
    {
      name = "task-priority"
      type = "N"
    },
    {
      name = "task-closed-timestamp"
      type = "N"
    }
  ]

  hash_key = "kanban-physical-id"
  range_key = "entity-physical-id"
  local_secondary_indexes = [{
    name : "idx-priority"
    range_key : "task-priority"
    projection_type : "ALL"
  }, {
    name : "idx-closed-timestamp"
    range_key :"task-closed-timestamp"
    projection_type : "ALL"
  }]
}

module "dynamodb_access_policy" {
  source = "./modules/iam_policy"

  path = "/kanban/"
  name = "kanban-dynamodb-access"
  statements = [{
    actions : [
      "dynamodb:Query",
      "dynamodb:PartiQLSelect",
    ]
    resources : [
      module.dynamodb-table.dynamodb_table_arn,
      "${module.dynamodb-table.dynamodb_table_arn}/index/idx-priority",
      "${module.dynamodb-table.dynamodb_table_arn}/index/idx-closed-timestamp",
    ]
  }, {
    actions : [
      "dynamodb:DescribeTable",

      "dynamodb:GetItem",
      "dynamodb:BatchGetItem",

      "dynamodb:ConditionCheckItem",

      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:PartiQLInsert",
      "dynamodb:PartiQLUpdate",

      "dynamodb:DeleteItem",
      "dynamodb:PartiQLDelete",
    ]
    resources : [
      module.dynamodb-table.dynamodb_table_arn
    ]
  }]
}

