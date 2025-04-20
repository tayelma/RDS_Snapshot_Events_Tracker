# Create the Lambda function.
resource "aws_lambda_function" "prod" {
  function_name    = var.lambdaVars["function_name"]
  filename         = "lambda_function.zip"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  memory_size      = 128
  package_type     = "Zip"
  role             = aws_iam_role.prod.arn
  skip_destroy     = false
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 30

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      s3_bucket = "rdssnapshottracker"
    }
  }

  logging_config {
    log_format = "Text"
    log_group  = aws_cloudwatch_log_group.snapshot.name
  }

  tags = {
    Name = "${var.lambdaVars["function_name"]}-Function"
  }

  depends_on = [
    aws_cloudwatch_log_group.snapshot,
  ]
}


resource "aws_cloudwatch_log_group" "snapshot" {
  name              = "/aws/lambda/${var.lambdaVars["function_name"]}"
  retention_in_days = 1

  tags = {
    Name = "${var.lambdaVars["function_name"]}-Lambda-LogGroup"
  }
}


