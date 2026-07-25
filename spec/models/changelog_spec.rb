# frozen_string_literal: true

require "rails_helper"
require "tempfile"

# Changelog (#1191) is a plain PORO -- no table -- so these specs exercise the real
# db/changelog.yml (the actual single source of truth for both the /changelog page and
# the footer's site version) plus two swapped-out fixture files for the ordering-trust and
# graceful-degradation guarantees the class' comments promise. Changelog.reset! is called
# around every example that touches SOURCE_FILE so memoization never leaks the real data
# into a fixture example, or a fixture's data into a later spec file (see the top-level
# `after`).
RSpec.describe Changelog do
  after { described_class.reset! }

  describe ".releases" do
    it "returns the real db/changelog.yml releases newest-first, in file order" do
      described_class.reset!

      expect(described_class.releases.map(&:version)).to eq(%w[1.3.0 1.2.0 1.1.0 1.0.0])
    end

    it "parses each entry into a Release with the right version/date/title/changes" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      described_class.reset!

      release = described_class.releases.first

      expect(release).to have_attributes(
        version: "1.3.0",
        date: Date.new(2026, 7, 22),
        title: "Build-in-public: this changelog"
      )
      expect(release.changes).to be_an(Array).and be_present
    end

    it "trusts the file's order rather than re-sorting by semver" do # rubocop:disable RSpec/ExampleLength
      out_of_order_yaml = <<~YAML
        - version: "0.1.0"
          date: 2026-01-01
          title: "Old release, listed first"
          changes:
            - "first"
        - version: "9.9.9"
          date: 2026-02-01
          title: "Newer release, listed second"
          changes:
            - "second"
      YAML

      with_changelog_fixture(out_of_order_yaml) do
        expect(described_class.releases.map(&:version)).to eq(%w[0.1.0 9.9.9])
      end
    end
  end

  describe ".current and .current_version" do
    it "returns the newest (topmost) release from .current" do
      described_class.reset!

      expect(described_class.current.version).to eq("1.3.0")
    end

    it "returns the newest release's version string from .current_version" do
      described_class.reset!

      expect(described_class.current_version).to eq("1.3.0")
    end
  end

  describe "graceful degradation" do
    it "returns no releases and a nil current_version when the source file is missing, without raising" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      stub_const("Changelog::SOURCE_FILE", Rails.root.join("db/does-not-exist-#{SecureRandom.hex(4)}.yml"))
      described_class.reset!

      expect { described_class.releases }.not_to raise_error
      expect(described_class.releases).to eq([])
      expect(described_class.current).to be_nil
      expect(described_class.current_version).to be_nil
    end

    it "returns no releases and a nil current_version when the source file is malformed YAML, without raising" do # rubocop:disable RSpec/MultipleExpectations
      with_changelog_fixture("not: valid: yaml: [") do
        expect { described_class.releases }.not_to raise_error
        expect(described_class.releases).to eq([])
        expect(described_class.current_version).to be_nil
      end
    end

    it "returns no releases when the file parses but is not an Array" do
      with_changelog_fixture("just_a_top_level_string") do
        expect(described_class.releases).to eq([])
      end
    end
  end

  # Writes `contents` to a real temp file, points Changelog::SOURCE_FILE at it for the
  # duration of the block, and forces a fresh parse before and after -- the least-hacky hook
  # the class exposes (it always reads from the SOURCE_FILE constant; there is no
  # dependency-injection seam beyond that).
  def with_changelog_fixture(contents)
    Tempfile.create(["changelog", ".yml"]) do |file|
      file.write(contents)
      file.flush

      stub_const("Changelog::SOURCE_FILE", Pathname.new(file.path))
      described_class.reset!

      yield
    end
  ensure
    described_class.reset!
  end
end
