variable "lambdaVars" {
  type = map(any)
  default = {
    function_name = "Snapshot-Tracker"
  }
}

variable "region" {
  type    = string
  default = "eu-west-1"
}

