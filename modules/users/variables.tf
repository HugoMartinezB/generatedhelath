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


variable "bastion_users" {
  description = "A map of the necessary bastion users."
  type        = map(any)
  default     = null
}


variable "bastion_host_id" {
  description = "Bastion host ID from the bastion module."
  type        = string
  default     = null
}

variable "topic_arn" {
  description = "SNS topic ARN."
  type        = string
  default     = null
}