# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'fileutils'
require 'tmpdir'

# Exercises the real bin/docker-entrypoint script as a subprocess. The only thing stubbed
# is `./bin/rails` itself (the external command it shells out to) -- the entrypoint script
# under test always runs for real, so a broken/removed db:seed call or a dropped `-e` flag
# would make these specs fail.
RSpec.describe 'bin/docker-entrypoint' do # rubocop:disable RSpec/DescribeClass
  let(:entrypoint) { File.expand_path('../../bin/docker-entrypoint', __dir__) }
  let(:log) { File.join(tmpdir, 'rails-calls.log') }

  around do |example|
    Dir.mktmpdir do |dir|
      @tmpdir = dir
      FileUtils.mkdir_p(File.join(dir, 'bin'))
      write_fake_rails
      example.run
    end
  end

  attr_reader :tmpdir

  # Writes a fake `./bin/rails` that records its first argument to `log` and, if that
  # argument matches `fail_on`, exits non-zero (simulating e.g. a failed migration).
  def write_fake_rails(fail_on: nil)
    File.write(File.join(tmpdir, 'bin', 'rails'), <<~SCRIPT)
      #!/bin/bash
      echo "$1" >> "#{log}"
      [ "$1" == "#{fail_on}" ] && exit 1
      exit 0
    SCRIPT
    FileUtils.chmod(0o755, File.join(tmpdir, 'bin', 'rails'))
  end

  def run_entrypoint(*args)
    Open3.capture3(entrypoint, *args, chdir: tmpdir)
  end

  def rails_calls
    File.exist?(log) ? File.readlines(log, chomp: true) : []
  end

  context 'when starting the rails server' do
    it 'migrates and seeds the database, in order, before exec-ing the server' do
      run_entrypoint('./bin/rails', 'server')

      expect(rails_calls).to eq(%w[db:prepare db:seed server])
    end

    it 'never seeds or starts the server if the migration fails' do
      write_fake_rails(fail_on: 'db:prepare')

      run_entrypoint('./bin/rails', 'server')

      expect(rails_calls).to eq(%w[db:prepare])
    end

    it 'exits non-zero if the migration fails' do
      write_fake_rails(fail_on: 'db:prepare')

      _stdout, _stderr, status = run_entrypoint('./bin/rails', 'server')

      expect(status).not_to be_success
    end

    it 'never starts the server if seeding fails' do
      write_fake_rails(fail_on: 'db:seed')

      run_entrypoint('./bin/rails', 'server')

      expect(rails_calls).to eq(%w[db:prepare db:seed])
    end

    it 'exits non-zero if seeding fails' do
      write_fake_rails(fail_on: 'db:seed')

      _stdout, _stderr, status = run_entrypoint('./bin/rails', 'server')

      expect(status).not_to be_success
    end
  end

  context 'when the command is not the rails server' do
    it 'does not migrate or seed before exec-ing the given command' do
      run_entrypoint('./bin/rails', 'console')

      expect(rails_calls).to eq(%w[console])
    end

    it 'does not migrate or seed for an unrelated command' do
      run_entrypoint('true')

      expect(rails_calls).to eq([])
    end
  end

  it 'replaces the process and propagates the exec-ed command exit status' do
    _stdout, _stderr, status = run_entrypoint('sh', '-c', 'exit 42')

    expect(status.exitstatus).to eq(42)
  end
end
