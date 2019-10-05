data "archive_file" "source" {
  type        = "zip"
  source_file = "${path.module}/authorizer.py"
  output_path = "${path.module}/authorizer.py.zip"
}

resource "aws_lambda_function" "authorizer" {
  filename         = "${path.module}/authorizer.py.zip"
  source_code_hash = "${data.archive_file.source.output_base64sha256}"
  function_name    = "authorizer"
  description      = "Basic auth authorizer for API Gateway"
  runtime          = "python3.6"
  role             = "${aws_iam_role.authorizer.arn}"
  handler          = "authorizer.lambda_handler"
  timeout          = 10

  lifecycle {
    # These will change even if the archive hashsum is the same.
    ignore_changes = ["filename", "last_modified"]
  }
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/lambda/${aws_lambda_function.authorizer.function_name}"
  retention_in_days = 14
}
