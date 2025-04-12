data "aws_caller_identity" "prod" {}


# Archive the Lambda function code.
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

data "aws_s3_bucket" "prod" {
  bucket = "rdssnapshottracker"
}







