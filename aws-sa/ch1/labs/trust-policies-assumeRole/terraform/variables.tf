variable "lab_name" {
  description = "Name identifier for this lab"
  type        = string
  default     = "trust-policies-assumeRole"
}

variable "aws_region" {
  description = "AWS region for lab deployment"
  type        = string
  default     = "us-east-1" # Cost-effective default
}

variable "external_id" {
  description = "External ID for additional security in trust policy"
  type        = string
  default     = "lab-external-id-12345"
  sensitive   = true
}

variable "session_duration" {
  description = "Maximum session duration for assumed role (in seconds)"
  type        = number
  default     = 3600 # 1 hour
  
  validation {
    condition = var.session_duration >= 900 && var.session_duration <= 43200
    error_message = "Session duration must be between 15 minutes (900 seconds) and 12 hours (43200 seconds)."
  }
}

variable "source_account_id" {
  description = "Source account ID (for cross-account scenarios)"
  type        = string
  default     = "" # Will use current account if empty
}

variable "developer_username" {
  description = "Username for the developer IAM user"
  type        = string
  default     = "lab-developer"
  
  validation {
    condition = can(regex("^[a-zA-Z0-9._-]+$", var.developer_username))
    error_message = "Developer username must contain only alphanumeric characters, periods, underscores, and hyphens."
  }
}
