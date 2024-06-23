variable "heroku_api_token" {
  description = "Heroku API token"
  type = string
}

variable "aws_profile" {
  default = "bitidev"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "management_key_pair_name" {
  default = "bitidev_aws_jeb"
}

variable "RAILS_MASTER_KEY" {
  type        = string
  description = "The master key used for decrypting the credentials files"
}
