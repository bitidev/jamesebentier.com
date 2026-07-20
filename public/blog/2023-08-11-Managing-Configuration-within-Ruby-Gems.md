---
slug: 2023-08-11-managing-configuration-within-ruby-gems
title: Managing Configuration within Ruby Gems
description: Two principles for gem configuration — a strong contract and freeze — to protect users from latent bugs and mutation hazards.
published_at: 2023-08-11
keywords: ruby, rubygems, configuration, dependency injection, immutability
image: /logo.png
tags:
- ruby
- rubygems
- configuration
kind: deep_dive
medium_url: https://engineering.invoca.com/managing-configuration-within-ruby-gems-cdc18e7172e
---

*Originally published on the [Invoca Engineering Blog](https://engineering.invoca.com/managing-configuration-within-ruby-gems-cdc18e7172e).*

A lot of times gems will need some form of configuration. Maybe it's a secret API key, a timeout threshold, or a set of default behaviors that users should be able to override. However you've approached gem configuration in the past, there are two main principles worth applying every time:

1. **Provide a strong contract** — make it clear what's required, catch problems at configuration time, not buried inside a feature call.
2. **Prevent configuration mutation with `freeze`** — protect both your library and your users from subtle latent bugs caused by unintended side effects.

## Provide a Strong Contract

Configuration is the first point of entry for anyone using your gem. If the configuration is invalid, the sooner you tell the user, the better — ideally the moment `configure` is called, not three nested calls later when the actual work fails with a confusing error.

The pattern: use a class, store the instance at the top level, and provide a `configure` class method that yields the new config and validates before storing it.

### Example Implementation

```ruby
module SomeGem
  class ConfigurationError < StandardError; end

  class Configuration
    attr_accessor :some_secret

    def validate!
      some_secret.present? or raise ConfigurationError,
                                    ':some_secret is required'
    end
  end

  class << self
    attr_reader :configuration

    def configure
      @configuration = Configuration.new.tap do |config|
        yield config
        config.validate!
      end
    end
  end
end
```

Walking through what each piece contributes:

- **`ConfigurationError`** — a dedicated exception class lets users rescue gem configuration problems specifically, rather than catching a generic `StandardError` and guessing the source.
- **`attr_accessor`** — gives callers a clean `config.some_secret = value` setter inside the block. Add one per configurable attribute.
- **`validate!`** — called at the end of `configure`, before the result is stored. If a required value is missing, the gem raises immediately. Users see the problem at startup, not buried inside a feature call.
- **`attr_reader :configuration`** — exposes the stored configuration read-only at the top-level namespace (`SomeGem.configuration`). Writers go through `configure`.
- **`configure` method** — the single entry point. It creates a fresh `Configuration`, yields it to the block, validates, and stores. Calling `configure` a second time replaces the previous configuration cleanly.

### Example Usage

```ruby
# Raises a ConfigurationError because the contract is not met
SomeGem.configure do |config|
  config.some_secret = nil
end

# Successfully configures the gem
SomeGem.configure do |config|
  config.some_secret = 'some_secret_value'
end
```

The first call fails fast and loudly. The second call succeeds and stores the configuration. Any code that tries to use the gem without calling `configure` at all will fail when it tries to access `SomeGem.configuration.some_secret` on a `nil` object — also a clear signal that setup was skipped.

## Prevent Configuration Mutation with `freeze`

Once the gem is configured, the global configuration object should be immutable. Without `freeze`, any code in the process — including application code or other gems — can silently modify `SomeGem.configuration.some_secret` at any point. These bugs are especially nasty to track down because the mutation may happen long before the symptom appears.

`freeze` makes the object immutable at the Ruby runtime level. Any attempt to modify a frozen object raises a `FrozenError` immediately, making the problem visible.

Pair `freeze` with dependency injection so that classes receive their configuration at construction time rather than reaching into the global state on every call. This also makes them easier to test with alternate configurations.

### Example Implementation

```ruby
module SomeGem
  # ...
  class << self
    # ...
    def configure
      @configuration = Configuration.new.tap do |config|
        yield config
        config.validate!
        config.freeze
      end
    end
  end

  class Encoder
    def initialize(configuration: SomeGem.configuration)
      @configuration = configuration
    end

    def encode(input)
      encode_with_some_secret(input, @configuration.some_secret)
    end
  end
end
```

### Example Usage

```ruby
SomeGem.configure do |config|
  config.some_secret = 'some_secret_value'
end

# Raises a FrozenError when trying to modify the global configuration
SomeGem.configuration.some_secret = 'some_other_secret_value'

# Encodes using the secret from the global configuration
SomeGem::Encoder.new.encode('some_string')

# Encodes using a different secret (useful in tests or multi-tenant scenarios)
temp_config = SomeGem::Configuration.new
temp_config.some_secret = 'some_other_secret_value'
temp_config.validate! # the caller takes responsibility for validity
SomeGem::Encoder.new(configuration: temp_config).encode('some_string')
```

The last pattern — constructing a local `Configuration`, validating it explicitly, and injecting it — is the right seam for tests and for any scenario where you need to use the gem with different credentials in the same process.

---

Writing gems with a strong configuration contract and frozen configuration objects is a small investment that pays dividends every time a user misconfigures your gem (they'll know immediately) and every time someone audits a production incident (the configuration is frozen, so it couldn't have changed under you). Both principles make your gem more trustworthy and the codebases that depend on it easier to reason about.
