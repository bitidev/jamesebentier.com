# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'json'

# config/environments/production.rb only takes effect when Rails actually boots in the
# production environment, so the only faithful way to verify it is to boot a real
# production-environment process (as Kamal/Docker would) and inspect the resulting
# config.hosts -- not to re-implement the same ENV-parsing logic in the test.
RSpec.describe 'config/environments/production.rb config.hosts' do # rubocop:disable RSpec/DescribeClass
  let(:fixed_hosts) do
    [
      'jamesebentier.com',
      /.*\.jamesebneiter\.com/.to_s,
      'jamesebentier-site-85eab09d3f4f.herokuapp.com'
    ]
  end

  def boot_production_hosts(additional_allowed_hosts: nil)
    env = { 'RAILS_ENV' => 'production', 'SECRET_KEY_BASE' => 'a' * 64,
            'ADDITIONAL_ALLOWED_HOSTS' => additional_allowed_hosts }.compact
    script = 'puts Rails.application.config.hosts.map(&:to_s).to_json'
    stdout, stderr, status = Open3.capture3(env, 'bundle', 'exec', 'rails', 'runner', script)
    raise "production boot failed: #{stderr}" unless status.success?

    JSON.parse(stdout)
  end

  it 'keeps the three fixed allowlist entries untouched when no override is set' do
    expect(boot_production_hosts).to eq(fixed_hosts)
  end

  it 'keeps the fixed allowlist entries untouched even when an override is set' do
    hosts = boot_production_hosts(additional_allowed_hosts: '203.0.113.10')

    expect(hosts[0...3]).to eq(fixed_hosts)
  end

  it 'appends a single ENV-supplied host so bare-IP verification works pre-DNS-cutover' do
    hosts = boot_production_hosts(additional_allowed_hosts: '203.0.113.10')

    expect(hosts).to eq(fixed_hosts + ['203.0.113.10'])
  end

  it 'appends every comma-separated ENV-supplied host, trimmed of surrounding whitespace' do
    hosts = boot_production_hosts(additional_allowed_hosts: ' 203.0.113.10 , staging.example.com ')

    expect(hosts).to eq(fixed_hosts + ['203.0.113.10', 'staging.example.com'])
  end

  it 'does not append anything when the override is set but blank' do
    hosts = boot_production_hosts(additional_allowed_hosts: '')

    expect(hosts).to eq(fixed_hosts)
  end
end
