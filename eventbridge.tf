# Create an EventBridge rule to catch RDS snapshot events.
resource "aws_cloudwatch_event_rule" "prod" {
  name        = "rds_snapshot_complete_rule"
  description = "Triggers when an RDS snapshot becomes available."
  event_pattern = jsonencode({
    "source" : ["aws.rds"]
  })

  tags = {
    Name = "${var.lambdaVars["function_name"]}-EventRule"
  }

}

# Set the EventBridge rule target to the Lambda function.
resource "aws_cloudwatch_event_target" "prod" {
  rule      = aws_cloudwatch_event_rule.prod.name
  target_id = "lambda"
  arn       = aws_lambda_function.prod.arn
}



