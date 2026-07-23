# frozen_string_literal: true

require "rails_helper"
# mini_magick is `require: false` in the Gemfile (not auto-loaded at boot), and this
# spec references the MiniMagick / MiniMagick::Tool constants in its let/before blocks
# before .call ever runs its own lazy require, so it must load the gem explicitly here.
require "mini_magick"

# lib/favicon/ico_assembler.rb -- the one step in the favicon pipeline (#1235 design
# doc) that shells out to real ImageMagick (via mini_magick) rather than rendering
# through Ferrum. `MiniMagick.convert` is the external system-process boundary (it is
# what actually invokes the `magick`/`convert` binary), so it is stubbed here the same
# way spec/lib/og_image/generator_spec.rb stubs Ferrum::Browser -- proving
# IcoAssembler's own wiring (which paths it hands to the tool, and in what order)
# without ever shelling out in the suite.
RSpec.describe Favicon::IcoAssembler do
  describe ".call" do
    let(:tool) { instance_double(MiniMagick::Tool, merge!: true, :<< => true) }
    let(:ico_path) { Rails.root.join("tmp/favicon_ico_assembler_spec_output.ico") }
    let(:png_paths) do
      [
        Rails.root.join("tmp/favicon-16.png"),
        Rails.root.join("tmp/favicon-32.png"),
        Rails.root.join("tmp/favicon-48.png")
      ]
    end

    before do
      allow(MiniMagick).to receive(:convert).and_yield(tool)
    end

    it "returns the given ico_path" do
      result = described_class.call(png_paths, ico_path)

      expect(result).to eq(ico_path)
    end

    it "merges the given PNG paths, as strings and in order, into the convert command" do
      described_class.call(png_paths, ico_path)

      expect(tool).to have_received(:merge!).with(png_paths.map(&:to_s))
    end

    it "appends the ico output path, as a string, as the final convert argument" do
      described_class.call(png_paths, ico_path)

      expect(tool).to have_received(:<<).with(ico_path.to_s)
    end

    it "never invokes the real MiniMagick::Tool (no shell-out in the suite)" do
      described_class.call(png_paths, ico_path)

      expect(MiniMagick).to have_received(:convert)
    end
  end
end
