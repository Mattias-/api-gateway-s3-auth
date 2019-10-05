data "aws_iam_policy_document" "authorizer" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_policy" "authorizer" {
  name_prefix = "authorizer-"
  policy      = "${data.aws_iam_policy_document.authorizer.json}"
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "authorizer" {
  name               = "authorizer"
  assume_role_policy = "${data.aws_iam_policy_document.lambda_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "authorizer" {
  role       = "${aws_iam_role.authorizer.name}"
  policy_arn = "${aws_iam_policy.authorizer.arn}"
}
