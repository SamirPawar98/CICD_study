provider "aws" {
  region = var.region
}

resource "aws_glue_job" "my_glue_job" {
  name     = "my-glue-job"
  role_arn = var.existing_glue_role_arn

  command {
    name            = "glueetl"
    script_location = var.glue_script_s3_path
    python_version  = "3"
  }

  glue_version = "4.0"
  max_capacity = 2
}

resource "aws_glue_crawler" "my_crawler" {
  name         = "my-glue-crawler"
  role         = var.existing_glue_role_arn
  database_name = "lottery-db"

  s3_target {
    path = "s3://your-bucket/lottery-data/"
  }

  schedule = "cron(0 12 * * ? *)"
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

resource "aws_lambda_function" "glue_trigger_lambda" {
  function_name = "trigger-glue-job"
  role          = var.existing_lambda_role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  timeout       = 30

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      GLUE_JOB_NAME = aws_glue_job.my_glue_job.name
    }
  }
}
