# Create an IAM role for the Lambda.
resource "aws_iam_role" "prod" {
  name = "${var.lambdaVars["function_name"]}-lambdaRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.lambdaVars["function_name"]}-lambdaRole"
  }

}

# Create a policy to allow Lambda to read/write the CSV in S3, describe RDS snapshots, and write logs.
resource "aws_iam_policy" "prod" {
  name        = "${var.lambdaVars["function_name"]}-lambdaPolicy"
  description = "Allow Lambda to access S3 bucket, describe RDS snapshots, and write logs."
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
          data.aws_s3_bucket.prod.arn,
          "${data.aws_s3_bucket.prod.arn}/*"
        ]
      },
      {
        Action = "rds:DescribeDBSnapshots",
        Effect = "Allow",
        Resource = [
          "arn:aws:rds:${var.region}:${data.aws_caller_identity.prod.account_id}:db:deposit",
          "arn:aws:rds:${var.region}:${data.aws_caller_identity.prod.account_id}:db:withdrawal",
          "arn:aws:rds:${var.region}:${data.aws_caller_identity.prod.account_id}:db:recon"
        ]
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "arn:aws:logs:${var.region}:${data.aws_caller_identity.prod.account_id}:log-group:/aws/lambda/${var.lambdaVars["function_name"]}:*"
      }
    ]
  })

  tags = {
    Name = "${var.lambdaVars["function_name"]}-lambdaPolicy"
  }
}

resource "aws_iam_role_policy_attachment" "prod" {
  role       = aws_iam_role.prod.name
  policy_arn = aws_iam_policy.prod.arn
}