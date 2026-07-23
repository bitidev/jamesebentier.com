# frozen_string_literal: true

require "rails_helper"

# lib/favicon/generator.rb (2026 terminal-identity redesign, epic #1179 / issue #1235
# design doc: replace the old favicon with the `>` terminal-prompt mark). Two layers,
# mirroring spec/lib/og_image/generator_spec.rb:
#
# - The committed public/ artifacts are what browsers, iOS home-screen add, and the PWA
#   manifest actually serve -- this is what would actually break if a file were missing,
#   corrupt, the wrong size, or (the bug this issue fixes) 0 bytes, so it gets real
#   assertions against the files' own bytes, no image gem.
# - Generator#call's wiring (its own logic: render each PNG_TARGETS size via Ferrum,
#   draw the SVG chevron -- not the "❯" glyph -- write PNGs to the right public
#   filenames, hand the 16/32/48 PNGs to IcoAssembler, always quit/clean up) is exercised
#   with Ferrum::Browser and Favicon::IcoAssembler -- the external system-process
#   boundaries -- stubbed, so the suite never launches Chrome or shells out to
#   ImageMagick.
RSpec.describe Favicon::Generator do
  describe "the committed public/ favicon and app-icon artifacts" do
    # PNG signature (8 bytes) + IHDR chunk: width/height as 4-byte big-endian integers
    # starting at byte 16 -- see spec/lib/og_image/generator_spec.rb's png_dimensions.
    def png_dimensions(path)
      bytes = File.binread(path, 24)
      width, height = bytes[16, 8].unpack("N2")
      [width, height]
    end

    def png_signature?(path)
      File.binread(path, 8).bytes == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
    end

    {
      "favicon-16x16.png" => [16, 16],
      "favicon-32x32.png" => [32, 32],
      "apple-touch-icon.png" => [180, 180],
      "apple-touch-icon-precomposed.png" => [180, 180],
      "logo192.png" => [192, 192],
      "logo512.png" => [512, 512],
      "logo.png" => [512, 512]
    }.each do |filename, expected_dimensions|
      describe filename do
        let(:path) { Rails.public_path.join(filename) }

        it "exists" do
          expect(File.exist?(path)).to be(true)
        end

        it "is a valid PNG (correct 8-byte file signature)" do
          expect(png_signature?(path)).to be(true)
        end

        it "is exactly #{expected_dimensions.join('x')}" do
          expect(png_dimensions(path)).to eq(expected_dimensions)
        end
      end
    end

    # These two were 0-byte files before #1235 (broken apple-touch-icon links on iOS
    # home-screen add) -- the regression this issue fixes, so it earns its own explicit
    # non-zero-size assertion beyond the generic PNG checks above.
    %w[apple-touch-icon.png apple-touch-icon-precomposed.png].each do |filename|
      it "#{filename} is no longer a 0-byte file" do
        expect(Rails.public_path.join(filename).size).to be > 0
      end
    end

    describe "favicon.ico" do
      let(:path) { Rails.public_path.join("favicon.ico") }

      # ICONDIR (6 bytes): reserved (must be 0), type (1 = icon), image count. Each
      # ICONDIRENTRY that follows is 16 bytes; its first two bytes are width/height (a
      # byte value of 0 means 256px, not reachable at these sizes). Reading this
      # directly needs no image gem and is the authoritative source for "what sizes does
      # this ICO actually contain."
      def ico_header(path)
        reserved, type, count = File.binread(path, 6).unpack("v3")
        [reserved, type, count]
      end

      def ico_entry_sizes(path)
        _reserved, _type, count = ico_header(path)
        (0...count).map do |i|
          width, height = File.binread(path, 2, 6 + (i * 16)).unpack("C2")
          [width.zero? ? 256 : width, height.zero? ? 256 : height]
        end
      end

      it "exists" do
        expect(File.exist?(path)).to be(true)
      end

      it "has a valid ICONDIR header (reserved=0, type=1/icon)" do
        reserved, type, = ico_header(path)

        expect([reserved, type]).to eq([0, 1])
      end

      it "contains exactly 3 images" do
        _reserved, _type, count = ico_header(path)

        expect(count).to eq(3)
      end

      it "contains the 16x16, 32x32, and 48x48 sizes" do
        expect(ico_entry_sizes(path)).to contain_exactly([16, 16], [32, 32], [48, 48])
      end
    end
  end

  describe "#call" do
    let(:browser) { instance_double(Ferrum::Browser, resize: true, goto: true, quit: true) }
    let(:public_path) { Pathname.new(Dir.mktmpdir("favicon_generator_spec")) }

    before do
      allow(Ferrum::Browser).to receive(:new).and_return(browser)
      # The real screenshot writes bytes to `path:`; Generator#call immediately copies
      # that file to each of its public/ filenames, so the stub has to leave a real
      # (dummy) file behind at the given path for that copy to succeed -- this is
      # Generator's own logic under test, not IcoAssembler's, so IcoAssembler itself is
      # stubbed out below rather than also exercising real ImageMagick.
      allow(browser).to receive(:screenshot) { |path:, **| FileUtils.touch(path) }
      allow(Favicon::IcoAssembler).to receive(:call).and_return(public_path.join("favicon.ico"))
    end

    after do
      FileUtils.rm_rf(public_path)
    end

    it "returns every PNG_TARGETS output path plus favicon.ico" do # rubocop:disable RSpec/ExampleLength
      result = described_class.call(public_path: public_path)

      expected = %w[
        favicon-16x16.png favicon-32x32.png apple-touch-icon.png
        apple-touch-icon-precomposed.png logo192.png logo512.png logo.png
      ].map { |filename| public_path.join(filename) } << public_path.join("favicon.ico")

      expect(result).to match_array(expected)
    end

    it "resizes the browser to every PNG_TARGETS size (16, 32, 48, 180, 192, 512)" do
      described_class.call(public_path: public_path)

      [16, 32, 48, 180, 192, 512].each do |size|
        expect(browser).to have_received(:resize).with(width: size, height: size)
      end
    end

    it "navigates to a local file:// HTML document that draws the chevron as an SVG path" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      captured_urls = []
      captured_html = []
      allow(browser).to receive(:goto) do |url|
        captured_urls << url
        captured_html << File.read(url.delete_prefix("file://"))
      end

      described_class.call(public_path: public_path)

      expect(captured_urls).to all(start_with("file://"))
      expect(captured_html).to all(
        include("<path", "stroke=\"#{described_class::CHEVRON_COLOR}\"")
          .and(include(described_class::CHEVRON_PATH))
      )
    end

    it "does NOT render the chevron via the literal Unicode glyph (tofu risk at small sizes)" do # rubocop:disable RSpec/ExampleLength
      captured_html = []
      allow(browser).to receive(:goto) do |url|
        captured_html << File.read(url.delete_prefix("file://"))
      end

      described_class.call(public_path: public_path)

      expect(captured_html).to all(satisfy { |html| html.exclude?("❯") })
    end

    it "writes a PNG file at every PNG_TARGETS public filename" do # rubocop:disable RSpec/ExampleLength
      described_class.call(public_path: public_path)

      %w[
        favicon-16x16.png favicon-32x32.png apple-touch-icon.png
        apple-touch-icon-precomposed.png logo192.png logo512.png logo.png
      ].each do |filename|
        expect(File.exist?(public_path.join(filename))).to be(true)
      end
    end

    it "hands IcoAssembler exactly the rendered 16/32/48 PNGs and the favicon.ico output path" do # rubocop:disable RSpec/MultipleExpectations
      described_class.call(public_path: public_path)

      expect(Favicon::IcoAssembler).to have_received(:call) do |png_paths, ico_path|
        expect(png_paths.map { |p| File.basename(p) }).to match_array(%w[favicon-16.png favicon-32.png favicon-48.png])
        expect(ico_path).to eq(public_path.join("favicon.ico"))
      end
    end

    it "quits the browser even when rendering raises (no leaked Chrome process)" do # rubocop:disable RSpec/MultipleExpectations
      allow(browser).to receive(:goto).and_raise(Ferrum::TimeoutError.new)

      expect { described_class.call(public_path: public_path) }.to raise_error(Ferrum::TimeoutError)
      expect(browser).to have_received(:quit)
    end

    it "removes its temp render directory even when rendering raises (no leaked tmp files)" do # rubocop:disable RSpec/MultipleExpectations, RSpec/ExampleLength
      captured_tmp_dir = nil
      allow(browser).to receive(:goto) do |url|
        captured_tmp_dir = File.dirname(url.delete_prefix("file://"))
        raise Ferrum::TimeoutError
      end

      expect { described_class.call(public_path: public_path) }.to raise_error(Ferrum::TimeoutError)
      expect(Dir.exist?(captured_tmp_dir)).to be(false)
    end
  end
end
