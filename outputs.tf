output "sqs_queue_name" {
  value       = "${aws_sqs_queue.archiver.name}"
  description = "Name of the SQS queue used to help process events"
}

output "sqs_queue_arn" {
  value       = "${aws_sqs_queue.archiver.arn}"
  description = "ARN of the SQS queue used to help process events"
}

output "lambda_function_name" {
  value       = "${aws_lambda_function.archiver.name}"
  description = "Name of the Lambda function processing events"
}

output "lambda_function_arn" {
  value       = "${aws_lambda_function.archiver.arn}"
  description = "ARN of the Lambda function processing events"
}
