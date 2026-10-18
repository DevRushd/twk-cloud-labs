provider "aws" {
  region = var.region

  # Credentials are supplied through the AWS CLI profile,
  # environment variables, or an attached IAM role.
}
