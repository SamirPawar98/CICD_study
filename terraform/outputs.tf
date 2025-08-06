output "lambda_function_name" {
  value = aws_lambda_function.glue_trigger_lambda.function_name
}

output "glue_job_name" {
  value = aws_glue_job.my_glue_job.name
}
