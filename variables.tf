variable "region" {
  type        = string
  description = "Region where infrastructure will be created"
  default     = "eu-west-2"
  sensitive   = true
}

# variable "allowed_origins" {
#   type        = string
#   description = "Comma-separated list of allowed origins for CORS"
#   default     = "https://main.d3m9wu6rhd9z99.amplifyapp.com,https://localhost:8080"
# }
