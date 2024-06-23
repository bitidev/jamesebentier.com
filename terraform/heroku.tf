resource "heroku_config" "web_config" {
  vars = {
    LOG_LEVEL                = "info"
    RACK_ENV                 = "production"
    RAILS_ENV                = "production"
    RAILS_LOG_TO_STDOUT      = "enabled"
    RAILS_SERVE_STATIC_FILES = "enabled"
  }

  sensitive_vars = {
    RAILS_MASTER_KEY = var.RAILS_MASTER_KEY
  }
}

resource "heroku_app" "web" {
  name   = "jamesebentier-site"
  region = "us"

  buildpacks = [
    "heroku/ruby",
  ]
}

resource "heroku_addon" "web_database" {
  app_id = heroku_app.web.id
  plan   = "schematogo:test"
}

resource "heroku_addon" "web_coralogix" {
  app_id = heroku_app.web.id
  plan   = "coralogix:free-30mbday"
}

resource "heroku_addon" "modlife_mailgun" {
  app_id = heroku_app.web.id
  plan   = "mailgun:starter"
}

resource "heroku_app_config_association" "web" {
  app_id         = heroku_app.web.id
  vars           = heroku_config.web_config.vars
  sensitive_vars = heroku_config.web_config.sensitive_vars
}
