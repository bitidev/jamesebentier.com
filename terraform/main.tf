provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

provider "heroku" {
  email   = "admin@biti.dev"
  api_key = var.heroku_api_token
}

terraform {
  backend "s3" {
    bucket  = "compupsych-infrastructure"
    key     = "terraform-state/jamesebentier.tfstate"
    region  = "eu-central-1"
    profile = "bitidev"
  }
}
