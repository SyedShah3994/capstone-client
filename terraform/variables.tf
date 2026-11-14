variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-2"
}

variable "my_ip_cidr" {
  description = "Public IP allowed to SSH, e.g. 203.0.113.10/32"
  type        = string
}
