// Decalring variables
variable "id" {
  description = "ID generated at the root module."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags from the root module."
  default     = null
}

variable "public_subnet_ids" {
  description = "List of public subnets IDs."
  type        = list(any)
  default     = null
}

variable "s3_bucket_name" {
  description = "Name of the data S3 bucket."
  type        = string
  default     = null
}

variable "whitelisted_ips" {
  description = "IP addresses to be whitelisted."
  type        = map(any)
  default     = null

}


variable "instance_type" {
  description = "Bastion host instance type."
  type        = string
  default     = "t3.micro"
}


variable "vpc_id" {
  description = "VPC ID from the aws-vpc module."
  type        = string
  default     = null
}