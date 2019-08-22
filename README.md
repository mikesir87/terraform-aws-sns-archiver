# SNS Archiver

This module adds a SQS subscription to a SNS topic and archives all received messages into S3.

```hcl
module "sns_archiver" {
  source            = "mikesir87/sns-archiver/aws"
  version           = "<latest tag>"
  namespace         = "example"
  sns_topic_name    = "my-topic"
  s3_bucket_name    = "bucket_name"
  archive_frequency = "rate(1 hour)"
  tags              = {}
}
```

## Resources

The archival works by doing the following:

- Creating a SQS queue and registering it as a subscriber to the SNS topic
- Deploys a Lambda function that will read the queue and store all SNS messages in S3, gzipped
- Creates a CloudWatch event rule that triggers the Lambda function based on the `archive_frequency`

The events are stored in S3 using the key `{namespace}/YEAR/MONTH/DAY/HOUR/MM-SS.json.gz`


## Inputs

| Variable | Description | Type | Default | Required |
| -------- | ----------- | ---- | ------- | -------- |
| namespace | Namespace for resources | string | - | yes |
| sns_topic_name | Name of the SNS topic being archived | string | - | yes |
| s3_bucket_name | Name of the S3 bucket the items will be archived in | string | - | yes |
| archive_frequency | Schedule expression for a CloudWatch rule (e.g rate(1 hour), cron(0 12 * * ? *)) | string | rate(1 hour) | no |
| lambda_timeout | Timeout for the Lambda function performing the archive (in seconds) | string | 60 | no |
| lambda_memory_size | Memory allocation for the Lambda function performing the archive | string | 128 | no |
| archive_frequency | Schedule expression for a CloudWatch rule (e.g rate(1 hour), cron(0 12 * * ? *)) | string | rate(1 hour) | no |
| tags | Additional tags to attach to resources | map | {} | no |


## Outputs

| Name | Description |
| ---- | ----------- |
| sqs_queue_name | Name of the SQS queue used to help process events |
| sqs_queue_arn  | ARN of the SQS queue used to help process events |
| lambda_function_arn  | ARN of the Lambda function processing events  |



## Contributing

Have a feature request? Found a bug? Use the Issue Tracker and start a discussion.
