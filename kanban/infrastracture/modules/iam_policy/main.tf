resource "aws_iam_policy" "this" {
  path = var.path
  name = var.name
  description = var.description
  policy = data.aws_iam_policy_document.this.json
}
data "aws_iam_policy_document" "this" {

  dynamic statement {
    for_each = var.statements

    content {
      actions = statement.value.actions
      resources = statement.value.resources
    }
  }
}