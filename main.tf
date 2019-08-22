data "aws_s3_bucket" "archival_store" {
  bucket = "${var.s3_bucket_name}"
}

data "aws_sns_topic" "sns" {
  name = "${var.sns_topic_name}"
}

resource "aws_sqs_queue" "archiver" {
  name = "${var.namespace}-sns-archiver"
  tags = "${var.tags}"
}

resource "aws_sqs_queue_policy" "archiver" {
  queue_url = "${aws_sqs_queue.archiver.id}"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "sqspolicy",
  "Statement": [
    {
      "Sid": "First",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "${aws_sqs_queue.archiver.arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "${data.aws_sns_topic.sns.arn}"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_sns_topic_subscription" "event_archiver" {
  topic_arn = "${data.aws_sns_topic.sns.arn}"
  protocol  = "sqs"
  endpoint  = "${aws_sqs_queue.archiver.arn}"
}

resource "aws_iam_role" "lambda_archiver" {
  name = "${var.namespace}-lambda-sns-archiver"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_archiver" {
  name = "sqs-and-s3-bucket-access"
  role = "${aws_iam_role.lambda_archiver.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "s3AndSqsAccess"
      "Action": [
        "sqs:DeleteMessage",
        "s3:PutObject",
        "sqs:ReceiveMessage",
        "s3:ListBucket"
      ],
      "Resource": [
        "${data.aws_s3_bucket.archival_store.arn}",
        "${data.aws_s3_bucket.archival_store.arn}/*",
        "${aws_sqs_queue.archiver.arn}"
      ]
    },
    {
      "Sid": "CheckAccess",
      "Action": [
        "s3:HeadBucket",
        "sqs:ListQueues"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "archiver" {
  name = "/aws/lambda/${var.namespace}-sns-archiver"
  tags = "${var.tags}"
}

data "archive_file" "function" {
  type        = "zip"
  output_path = "/tmp/function.zip"
  source_file = "${path.module}/fn/src/index.js"
}

resource "aws_lambda_function" "archiver" {
  function_name    = "${var.namespace}-sns-archiver"
  description      = "SNS Archiver - ${var.namespace}"
  role             = "${aws_iam_role.lambda_archiver.arn}"
  runtime          = "nodejs10.x"
  handler          = "index.lambdaHandler"
  filename         = "${data.archive_file.function.output_path}"
  source_code_hash = "${filebase64sha256(data.archive_file.function.output_path)}"

  environment {
    variables = {
      BUCKET_NAME = "${var.s3_bucket_name}"
      QUEUE_NAME  = "${aws_sqs_queue.archiver.name}"
    }
  }

  tags = "${var.tags}"
}

resource "aws_cloudwatch_event_rule" "archiver" {
  name                = "${var.namespace}-archive-trigger"
  description         = "Archiver trigger"
  schedule_expression = "${var.archive_frequency}"
}

resource "aws_cloudwatch_event_target" "archiver" {
  rule      = "${aws_cloudwatch_event_rule.archiver.name}"
  target_id = "${var.namespace}-archiver"
  arn       = "${aws_lambda_function.archiver.arn}"
}

resource "aws_lambda_permission" "archiver" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.archiver.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.archiver.arn}"
}
