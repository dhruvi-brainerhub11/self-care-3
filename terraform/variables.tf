variable "aws_region" {
  type        = string
  description = "AWS region containing the default VPC."
  default     = "us-east-1"
}

variable "name" {
  type        = string
  description = "Prefix used for AWS resource names."
  default     = "selfcare-app"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance size."
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "Name of an existing EC2 key pair."
}

variable "ssh_ingress_cidr" {
  type        = string
  description = "CIDR allowed to SSH to EC2, ideally your fixed IP with /32."

  validation {
    condition     = can(cidrhost(var.ssh_ingress_cidr, 0))
    error_message = "ssh_ingress_cidr must be a valid CIDR range."
  }
}

variable "developer_cidr" {
  type        = string
  description = "Optional CIDR allowed to connect directly to public RDS for local development. Leave empty in production."
  default     = ""

  validation {
    condition     = var.developer_cidr == "" || can(cidrhost(var.developer_cidr, 0))
    error_message = "developer_cidr must be empty or a valid CIDR range."
  }
}

variable "db_publicly_accessible" {
  type        = bool
  description = "Enable public RDS addressing only when direct local development access is needed."
  default     = false
}

variable "db_name" {
  type        = string
  description = "Initial MySQL database name."
  default     = "selfcare"
}

variable "db_username" {
  type        = string
  description = "RDS master username."
}

variable "db_password" {
  type        = string
  description = "RDS master password. Also stored in Terraform state; protect the state file."
  sensitive   = true
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance size."
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "RDS storage size in GiB."
  default     = 20
}

variable "db_multi_az" {
  type        = bool
  description = "Enable Multi-AZ RDS deployment for higher availability."
  default     = false
}

variable "db_deletion_protection" {
  type        = bool
  description = "Protect the RDS instance from accidental deletion."
  default     = true
}