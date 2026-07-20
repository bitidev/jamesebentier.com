# Newsletter Mail — Operations Note

## Current state (v1): log-only delivery

Both `development` and `production` use the custom `Mail::LoggerDelivery` method defined in
`lib/mail/logger_delivery.rb`. No email is sent externally; instead, the full message is
written to the Rails log at `:info` level. The relevant configuration lives in
`config/environments/development.rb` and `config/environments/production.rb`:

```ruby
require Rails.root.join("lib/mail/logger_delivery")
config.action_mailer.delivery_method = :logger
config.action_mailer.logger_settings  = { log_level: :info }
```

In development you'll see a block like this in the Rails log whenever a signup triggers:

```
[NewsletterMailer] ── Would send email ──────────────────────────────────
  To:      user@example.com
  From:    james@jamesebentier.com
  Subject: Confirm your subscription to James Ebentier's newsletter
  ── Body (text/plain) ──────────────────────────────────────────────────
  Confirm your subscription …
  http://localhost:3000/newsletter/confirm?token=…
  ──────────────────────────────────────────────────────────────────────
```

Copy the confirm URL from the log to test the double opt-in flow locally.

## Swapping in a real ESP

When an email service provider is chosen, replace the logger delivery config with the
provider-specific settings. The `NewsletterMailer` and `Subscriber` model do not need to
change — only the delivery method configuration.

### Postmark example

```ruby
# Gemfile
gem "postmark-rails"

# config/environments/production.rb
config.action_mailer.delivery_method = :postmark
config.action_mailer.postmark_settings = { api_token: ENV.fetch("POSTMARK_API_TOKEN") }
config.action_mailer.default_url_options = { host: "jamesebentier.com", protocol: "https" }
```

### Generic SMTP example

```ruby
# config/environments/production.rb
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  address:              ENV.fetch("SMTP_HOST"),
  port:                 587,
  domain:               "jamesebentier.com",
  user_name:            ENV.fetch("SMTP_USER"),
  password:             ENV.fetch("SMTP_PASSWORD"),
  authentication:       :plain,
  enable_starttls_auto: true
}
```

## IP pepper

The `Subscriber#ip_hash_for` helper hashes the signup IP with a pepper for privacy. Set
`NEWSLETTER_IP_PEPPER` in the production environment to a long random secret
(`openssl rand -hex 32`). Without it, the first 32 characters of `secret_key_base` are
used as a fallback.

## Related issues

- **#1186** — this feature (newsletter signup, double opt-in, log-only delivery)
- **#1190** — full privacy policy page (replaces the current `/privacy` stub)
