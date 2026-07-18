# frozen_string_literal: true

require 'spec_helper'

# .kamal/secrets is committed to git, so every value in it must be a reference (an ENV
# var or a shell command substitution) that Kamal resolves at deploy time -- never a
# literal secret. See spec R1/.kamal/secrets and the acceptance criterion:
# "'.kamal/secrets' contains only environment/command references, never a literal secret
# value".
RSpec.describe '.kamal/secrets' do # rubocop:disable RSpec/DescribeClass
  let(:path) { File.expand_path('../../.kamal/secrets', __dir__) }

  let(:declared) do
    File.readlines(path).filter_map do |line|
      stripped = line.strip
      next if stripped.empty? || stripped.start_with?('#')

      key, value = stripped.split('=', 2)
      [key, value]
    end.to_h
  end

  it 'declares exactly the secrets this deploy actually wires up (R1/R3/R4/R5)' do
    expect(declared.keys).to contain_exactly(
      'KAMAL_REGISTRY_PASSWORD', 'RAILS_MASTER_KEY', 'POSTGRES_PASSWORD', 'DATABASE_URL'
    )
  end

  it 'never assigns a literal value -- every secret is an ENV var or command-substitution reference' do
    declared.each do |key, value|
      expect(value).to include('$'), "expected #{key}=#{value.inspect} to reference ENV or a command, not a literal value"
    end
  end

  it 'derives DATABASE_URL from the same postgres accessory credentials, reachable by its Kamal hostname (R4)' do
    expect(declared['DATABASE_URL']).to eq(
      'postgres://jamesebentier_site:$POSTGRES_PASSWORD@jamesebentier-site-postgres:5432/jamesebentier_site_production'
    )
  end
end
