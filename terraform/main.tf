# provider "aws" {
#   region = var.region
# }

# resource "aws_glue_job" "my_glue_job" {
#   name     = "my-glue-job"
#   role_arn = var.existing_glue_role_arn

#   command {
#     name            = "glueetl"
#     script_location = var.glue_script_s3_path
#     python_version  = "3"
#   }

#   glue_version = "4.0"
#   max_capacity = 2
# }

# resource "aws_glue_crawler" "my_crawler" {
#   name         = "my-glue-crawler"
#   role         = var.existing_glue_role_arn
#   database_name = "lottery-db"

#   s3_target {
#     path = "s3://your-bucket/lottery-data/"
#   }

#   schedule = "cron(0 12 * * ? *)"
# }

# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_file = "${path.module}/lambda_function.py"
#   output_path = "${path.module}/lambda_function.zip"
# }

# resource "aws_lambda_function" "glue_trigger_lambda" {
#   function_name = "trigger-glue-job"
#   role          = var.existing_lambda_role_arn
#   handler       = "lambda_function.lambda_handler"
#   runtime       = "python3.10"
#   timeout       = 30

#   filename         = data.archive_file.lambda_zip.output_path
#   source_code_hash = data.archive_file.lambda_zip.output_base64sha256

#   environment {
#     variables = {
#       GLUE_JOB_NAME = aws_glue_job.my_glue_job.name
#     }
#   }
# }

# Configure the AWS provider with the specified region
provider "aws" {
  region = var.aws_region
}

###############################################
# AWS Glue Job for Data Transformation
###############################################
resource "aws_glue_job" "transform_job" {
  name     = "lottery-transform-job"                   # Glue job name
  role_arn = var.iam_role                              # IAM role ARN

  # Job command and script settings
  command {
    name            = "glueetl"                        # Job type (glueetl = Spark ETL)
    script_location = var.glue_script_s3_path          # S3 path to transformation script
    python_version  = "3"                              # Use Python 3
  }

  # Retry and timeout configurations
  max_retries = 0                                     # Retry once if the job fails
  timeout     = 60                                     # Timeout in minutes
  glue_version = "5.0"                                 # Glue runtime version

  # Optional: Specify number of workers and type
  number_of_workers = 2                                # Number of DPUs
  worker_type       = "G.1X"                           # Worker type (G.1X or G.2X)

  # Optional: Job description
  description = "ETL job to transform lottery data"

  
}

###############################################
# AWS Glue Crawler for Transformed Data
###############################################
resource "aws_glue_crawler" "transformed_data_crawler" {
  name          = "lottery-transformed-crawler"        # Unique name of the crawler
  role          = var.iam_role                         # IAM role used by the crawler
  database_name = var.transformed_glue_database        # Glue database to store transformed data catalog

  # Define the S3 data source for crawling transformed data
  s3_target {
    path = var.transformed_data_s3_path                # S3 path to transformed data
  }

  # Optional: Crawler output behavior
  configuration = jsonencode({
    Version = 1.0,
    CrawlerOutput = {
      Partitions = { AddOrUpdateBehavior = "InheritFromTable" }
    }
  })

  
}

###############################################
# Trigger Resource (Runs Glue Job and Crawler)
###############################################
resource "null_resource" "trigger_glue_flow" {
  # Ensure dependencies are created before running the commands
  depends_on = [
    aws_glue_job.transform_job,
    aws_glue_crawler.transformed_data_crawler
  ]

  # Run the job and crawler using local AWS CLI
  provisioner "local-exec" {
    command = <<EOT
      echo "Starting Glue Job..." && \
      aws glue start-job-run --job-name lottery-transform-job && \
      echo "Waiting for job to complete..." && \
      sleep 120 && \
      echo "Starting Transformed Data Crawler..." && \
      aws glue start-crawler --name lottery-transformed-crawler
    EOT
  }
}

