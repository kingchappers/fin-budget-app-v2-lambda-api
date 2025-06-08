variable "region" {
  type        = string
  description = "Region where infrastructure will be created"
  default     = "eu-west-2"
  sensitive   = true
}
