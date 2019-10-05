provider "aws" {
  region = "eu-north-1"
}

provider "archive" {}

resource "aws_api_gateway_rest_api" "s3_proxy" {
  name                     = "s3-proxy"
  minimum_compression_size = 10485760
}

resource "aws_api_gateway_resource" "bucket" {
  rest_api_id = "${aws_api_gateway_rest_api.s3_proxy.id}"
  parent_id   = "${aws_api_gateway_rest_api.s3_proxy.root_resource_id}"
  path_part   = "{object+}"
}

resource "aws_api_gateway_method" "bucket_get" {
  rest_api_id   = "${aws_api_gateway_rest_api.s3_proxy.id}"
  resource_id   = "${aws_api_gateway_resource.bucket.id}"
  http_method   = "GET"
  authorization = "CUSTOM"
  authorizer_id = "${aws_api_gateway_authorizer.basic_auth.id}"

  request_parameters = {
    "method.request.path.object" = true
  }
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = "${aws_api_gateway_rest_api.s3_proxy.id}"
  resource_id             = "${aws_api_gateway_resource.bucket.id}"
  http_method             = "${aws_api_gateway_method.bucket_get.http_method}"
  type                    = "AWS"
  timeout_milliseconds    = 29000
  credentials             = "arn:aws:iam::253037940910:role/GetAll"
  integration_http_method = "GET"
  uri                     = "arn:aws:apigateway:eu-north-1:s3:path/{object}"

  request_parameters = {
    "integration.request.path.object" = "method.request.path.object"
  }
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${aws_api_gateway_rest_api.s3_proxy.id}"
  resource_id = "${aws_api_gateway_resource.bucket.id}"
  http_method = "${aws_api_gateway_method.bucket_get.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = "${aws_api_gateway_rest_api.s3_proxy.id}"
  resource_id = "${aws_api_gateway_resource.bucket.id}"
  http_method = "${aws_api_gateway_method.bucket_get.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = "${aws_api_gateway_rest_api.s3_proxy.id}"
  stage_name  = "v1"
  depends_on  = ["aws_api_gateway_integration.integration"]
}

resource "aws_api_gateway_authorizer" "basic_auth" {
  name = "basic_auth"

  rest_api_id            = "${aws_api_gateway_rest_api.s3_proxy.id}"
  authorizer_uri         = "${aws_lambda_function.authorizer.invoke_arn}"
  authorizer_credentials = "${aws_iam_role.invocation_role.arn}"

  authorizer_result_ttl_in_seconds = 300
  identity_validation_expression   = "^Basic .*$"
}

output "invoke_url" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}"
}
