variable "region" {
  description = "AWS region for deployment."
  type        = string
  default     = "eu-west-1"
}

variable "az" {
  description = "AWS Availability Zone for the subnet and instance."
  type        = string
  default     = "eu-west-1a"
}

variable "enterprise_project_id" {
  description = "Enterprise project to bill and group resources under. null = default project."
  type        = string
  default     = null
}

variable "env_prefix" {
  type    = string
  default = "twk"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.60.0.0/16"
}

variable "dev_subnet_cidr" {
  description = "CIDR block for the development subnet."
  type        = string
  default     = "10.60.2.0/24"
}

variable "instance_name" {
  type    = string
  default = "twk-dev"
}

variable "instance_type" {
  description = "AWS EC2 instance type. Adjust to your workload and budget."
  type        = string
  default     = "c7i-flex.large"
}

variable "image_name" {
  description = "Description of the desired OS image; the EC2 AMI should be looked up separately."
  type        = string
  default     = "Ubuntu 22.04 LTS"
}

variable "system_disk_size" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 40
}

variable "data_disk_size" {
  description = "Additional EBS data volume size in GiB."
  type        = number
  default     = 100
}

variable "ssh_cidr" {
  description = "Your public IP in CIDR form, e.g. 203.0.113.10/32. Only this address may use SSH."
  type        = string

  validation {
    condition     = can(cidrhost(var.ssh_cidr, 0))
    error_message = "ssh_cidr must be a valid IPv4 or IPv6 CIDR block."
  }
}

variable "ssh_key_name" {
  description = "Name of the AWS EC2 key pair."
  type        = string
  default     = "twk-dev-key"
}

variable "ssh_public_key" {
  description = "The PUBLIC half of your SSH key. Never supply the private key."
  type        = string
}

variable "s3_bucket_name" {
  description = "Globally unique S3 bucket name for state or backups."
  type        = string
}

variable "tags" {
  type = map(string)

  default = {
    project    = "twk"
    env        = "dev"
    managed-by = "terraform"
  }
}
