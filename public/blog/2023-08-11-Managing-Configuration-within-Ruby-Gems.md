---
slug: 2023-08-11-managing-configuration-within-ruby-gems
title: Managing Configuration within Ruby Gems
description: A lot of times gems will need some form of configuration in order to perform its tasks. Two principles make that safer — a strong contract, and freeze.
published_at: 2023-08-11
keywords: ruby, rubygems, configuration, dependency injection, immutability, configuration management
image: /logo.png
tags:
- rubygems
- ruby
- dependency-injection
- configuration-management
- immutability
kind: deep_dive
medium_url: https://engineering.invoca.com/managing-configuration-within-ruby-gems-cdc18e7172e
---

*Originally published on the [Invoca Engineering Blog](https://engineering.invoca.com/managing-configuration-within-ruby-gems-cdc18e7172e).*

A lot of times gems will need some form of configuration in order to perform its tasks, whether it be a logger for observability, a default instance for ease of use, secrets for (en/de)crypting payloads, or just flags for changing default behavior. There are two main principles to follow when setting up global configuration that will make the lives of your gem users easier: (1) Provide a strong contract and (2) Prevent configuration mutation with `freeze`.

## Provide a Strong Contract

Configuration is the first point of entry in any gem, and without proper enforcement of required and proper configuration you allow your users to deal with latent bugs and tiger traps due to invalid or incomplete configuration. To help with establishing a strong contract we can:

1. Use a class to encapsulate the `Configuration` object
2. Store the current configuration at the top-level namespace of the gem
3. Provide a `configure` method at the top-level namespace which sets the global configuration and enforces the contract through validations

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

Let's take the above code as an example implementation and walk through what it's doing:

1. `class ConfigurationError < StandardError; end`: We define an error class for the gem to increase clarity into what type of error is being raised to the user of the gem
2. `attr_accessor :some_secret`: Since the configuration has no default value, an `attr_accessor` is used to implement getters and setters for the instance variable
3. `def validate!`: A validation method is defined within the `Configuration` class to enforce the strict contract
4. `attr_reader :configuration`: To restrict the contract for setting the global configuration, we only define a getter for the top-level `configuration` instance variable
5. `def configure`: In order to force global configuration to validate the strict contract, this is the only supported way to set the global configuration where it yields a fresh configuration to the caller and validates the object before storing it.

### Example Usage

So what does this look like when used by another project.

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

## Prevent configuration mutation with freeze

Latent bugs will hide whenever there is a global configuration that allows for mutation. Along the line, some code path will want a slightly different configuration, and try to mutate the global config for this exact reason, causing other users of parts of your code to break, or act in an unexpected way. To avoid this we can do two things:

1. Freeze the global configuration object after it's created to prevent global mutation
2. Use dependency injection to allow objects/method to be passed a specific instance of the `Configuration` to use, and default to the global config

### Example Implementation

Let's build upon the above example implementation to add in these new parts of the contract and adding a class that uses the configured attribute `some_secret`:

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

Let's break down what is added in the above code:

1. `def configure`: Is now expanded to also call `freeze` on the config object after validating it. This locks all instance variables from being mutated
2. `class Encoder`: Is added with a method that uses `some_secret` and through dependency injection, we allow the user to provide the encoder object a specific configuration, but default to the global configuration when one is not provided.

### Example Usage

Using the new implementation above, we're able to provide more flexibility to the users of our gem, and they don't need to juggle the complexities and dangers of global configuration on their own:

```ruby
SomeGem.configure do |config|
  config.some_secret = 'some_secret_value'
end

# Raises a frozen object error when trying to modify the global configuration
SomeGem.configuration.some_secret = 'some_other_secret_value'

# Encodes using the secret from the global configuration
SomeGem::Encoder.new.encode('some_string')

# Encodes using a different secret
temp_config = SomeGem::Configuration.new
temp_config.some_secret = 'some_other_secret_value'
temp_config.validate! # The user has to take responsibility for the config being valid
SomeGem::Encoder.new(configuration: temp_config).encode('some_string')
```

When writing gems, it's important to think about how they need to be configured, as well as how they will be used. Some gems will only require a global configuration, while others need more flexibility, but strong contracts and immutable configurations will help protect your users from latent bugs and erroneous code.
