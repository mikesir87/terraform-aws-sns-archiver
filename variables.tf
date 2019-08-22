variable "namespace" {
  description = "Namespace for resources"
  type        = "string"
}

variable "sns_topic_name" {
  description = "Name of the SNS topic being archived"
  type        = "string"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket the items will be archived in"
  type        = "string"
}

variable "archive_frequency" {
  description = "Schedule expression for a CloudWatch rule (e.g rate(1 hour), cron(0 12 * * ? *))"
  type        = "string"
  default     = "rate(1 hour)"
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function performing the archive (in seconds)"
  type        = "string"
  default     = "60"
}

variable "lambda_memory_size" {
  description = "Memory allocation for the Lambda function performing the archive"
  type        = "string"
  default     = "128"
}

variable "tags" {
  description = "Additional tags to attach to resources"
  type        = "map"
  default     = {}
}
