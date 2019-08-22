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

variable "tags" {
  description = "Additional tags to attach to resources"
  type        = "map"
  default     = {}
}
