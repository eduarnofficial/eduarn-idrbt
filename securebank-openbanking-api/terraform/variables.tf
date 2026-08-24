variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "api_name" {
  type    = string
  default = "securebank-openbanking-api"
}

variable "backend_url" {
  description = "Public HTTPS URL of the deployed FastAPI backend."
  type        = string
}
