variable "region" {
  default = "us-east-1"
}

variable "glue_script_s3_path" {
  default = "s3://your-bucket/scripts/glue_job.py"
}

variable "existing_glue_role_arn" {
  description = "Pre-created IAM Role ARN for AWS Glue"
  type        = string
  default     = "arn:aws:iam::123456789012:role/existing-glue-role"
}

variable "existing_lambda_role_arn" {
  description = "Pre-created IAM Role ARN for Lambda"
  type        = string
  default     = "arn:aws:iam::123456789012:role/existing-lambda-role"
}
