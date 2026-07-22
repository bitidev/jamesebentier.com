# frozen_string_literal: true

require "rails_helper"

# lib/og_image/generator.rb (#1189 design doc's "OG image strategy" decision: a single
# committed static branded default, not a per-request/per-post render). Two layers:
#
# - The committed artifact itself (public/og-default.png) is what every page actually
#   serves as its og:image/twitter:image/JSON-LD image fallback -- this is the thing that
#   would actually break Open Graph cards if it were missing, corrupt, or the wrong size, so
#   it gets a real assertion against the file's own PNG header, not a mock.
# - Generator#call's wiring (its only real logic: build an HTML tempfile, drive a headless
#   browser at the right dimensions, screenshot to the given output path, always quit) is
#   exercised with Ferrum::Browser -- an external system-process boundary -- stubbed, so the
#   suite never launches a real Chrome process (slow/flaky in CI) while still proving the
#   generator's own code, not the mock, does the work.
RSpec.describe OgImage::Generator do
  describe "the committed public/og-default.png artifact" do
    let(:png_path) { Rails.public_path.join("og-default.png") }

    # PNG signature (8 bytes) + IHDR chunk: 4-byte length, 4-byte "IHDR" type, then width
    # and height as 4-byte big-endian integers -- reading this directly needs no image gem
    # and is the authoritative source for "what size is this file", independent of whatever
    # OgImage::Generator::WIDTH/HEIGHT currently say.
    def png_dimensions(path)
      bytes = File.binread(path, 24)
      width, height = bytes[16, 8].unpack("N2")
      [width, height]
    end

    it "exists" do
      expect(File.exist?(png_path)).to be(true)
    end

    it "is a valid PNG (correct 8-byte file signature)" do
      signature = File.binread(png_path, 8)

      expect(signature.bytes).to eq([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
    end

    it "is exactly 1200x630 -- the summary_large_image / Rich Results recommended size" do
      expect(png_dimensions(png_path)).to eq([1200, 630])
    end

    it "matches Generator::WIDTH/HEIGHT (the constants the generator itself renders at)" do
      expect(png_dimensions(png_path)).to eq([described_class::WIDTH, described_class::HEIGHT])
    end
  end

  describe "#call" do
    let(:browser) { instance_double(Ferrum::Browser, resize: true, goto: true, screenshot: true, quit: true) }
    let(:output_path) { Rails.root.join("tmp/og_image_generator_spec_output.png") }

    before do
      allow(Ferrum::Browser).to receive(:new).and_return(browser)
    end

    after do
      FileUtils.rm_f(output_path)
    end

    it "returns the output path it was given" do
      result = described_class.call(output_path: output_path)

      expect(result).to eq(output_path)
    end

    it "resizes the browser to the exact WIDTHxHEIGHT the OG image spec requires" do
      described_class.call(output_path: output_path)

      expect(browser).to have_received(:resize).with(width: described_class::WIDTH, height: described_class::HEIGHT)
    end

    it "navigates to a local file:// HTML document containing the real branded template" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      captured_url = nil
      # Read the HTML tempfile's content from inside the goto stub, synchronously, while
      # Generator#call still holds it open -- its `ensure` unlinks the tempfile immediately
      # after screenshot() returns, so reading it after `call` finishes would 404.
      captured_html = nil
      allow(browser).to receive(:goto) do |url|
        captured_url = url
        captured_html = File.read(url.delete_prefix("file://"))
      end

      described_class.call(output_path: output_path)

      expect(captured_url).to start_with("file://")
      expect(captured_html).to include("James Ebentier", "Software Architect")
    end

    it "screenshots to the given output path, binary-encoded" do
      described_class.call(output_path: output_path)

      expect(browser).to have_received(:screenshot).with(path: output_path.to_s, encoding: :binary)
    end

    it "quits the browser even when the screenshot itself raises (no leaked Chrome process)" do # rubocop:disable RSpec/MultipleExpectations
      allow(browser).to receive(:screenshot).and_raise(Ferrum::TimeoutError.new)

      expect { described_class.call(output_path: output_path) }.to raise_error(Ferrum::TimeoutError)
      expect(browser).to have_received(:quit)
    end
  end
end
