terraform {
  required_version = "~> 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }

    heroku = {
      source  = "heroku/heroku"
      version = "~> 5.2"
    }
  }
}
