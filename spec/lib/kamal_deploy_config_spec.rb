# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'yaml'

# Exercises `kamal config`, which ERB-resolves the real config/deploy.yml against actual
# ENV vars and validates it against Kamal's own schema -- the same resolution Kamal
# performs before every `kamal setup`/`kamal deploy`/`kamal accessory boot` invocation.
RSpec.describe 'config/deploy.yml (via `kamal config`)' do # rubocop:disable RSpec/DescribeClass
  let(:base_env) do
    {
      'KAMAL_HOST' => '203.0.113.10',
      'KAMAL_SSH_USER' => 'deploy',
      'KAMAL_REGISTRY_USERNAME' => 'someuser',
      'ADDITIONAL_ALLOWED_HOSTS' => '203.0.113.10'
    }
  end

  def resolved_config(env_overrides = {})
    env = base_env.merge(env_overrides)
    stdout, stderr, status = Open3.capture3(env, 'bundle', 'exec', 'kamal', 'config')

    raise "kamal config failed: #{stderr}#{stdout}" unless status.success?

    YAML.safe_load(stdout, permitted_classes: [Symbol])
  end

  it 'targets exactly one host, resolved from KAMAL_HOST rather than hardcoded (R1)' do
    config = resolved_config('KAMAL_HOST' => '198.51.100.42')

    expect(config[:hosts]).to eq(['198.51.100.42'])
  end

  it 'uses KAMAL_SSH_USER for the deploy SSH user (R1)' do
    config = resolved_config('KAMAL_SSH_USER' => 'deploy_bot')

    expect(config[:ssh_options][:user]).to eq('deploy_bot')
  end

  it 'pushes/pulls the app image through ghcr.io (R5)' do
    config = resolved_config

    expect(config[:repository]).to start_with('ghcr.io/')
  end

  it 'runs the postgres accessory on the same host as the app (R3)' do
    config = resolved_config('KAMAL_HOST' => '203.0.113.10')

    expect(config[:accessories]['postgres']['host']).to eq('203.0.113.10')
  end

  it 'persists the postgres accessory data across restarts (R3)' do
    config = resolved_config

    expect(config[:accessories]['postgres']['directories']).to include('data:/var/lib/postgresql/data')
  end

  it 'resolves successfully when ADDITIONAL_ALLOWED_HOSTS is not set at all, per R6 "if present"' do
    # Regression: config/deploy.yml's env.clear.ADDITIONAL_ALLOWED_HOSTS ERB-interpolates
    # ENV["ADDITIONAL_ALLOWED_HOSTS"] directly, which is nil (not a string) when the
    # operator hasn't set it. Kamal's schema rejects nil for env/clear values, so every
    # `kamal` command (config/setup/deploy/accessory boot) fails outright -- not just the
    # IP-allowlist feature -- contradicting R6's "if present" framing that this var is
    # optional. See spec R6 and docs/ops/kamal-first-deploy.md.
    expect { resolved_config('ADDITIONAL_ALLOWED_HOSTS' => nil) }.not_to raise_error
  end
end
