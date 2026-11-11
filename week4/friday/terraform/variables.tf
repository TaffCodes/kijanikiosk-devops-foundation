variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "ssh_key_name" {
  description = "Name of the AWS key pair to use for SSH access"
  type        = string
  default     = "kijanikiosk-key"
}